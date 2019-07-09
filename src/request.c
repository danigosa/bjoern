#include <Python.h>
#include <string.h>
#include "request.h"
#include "filewrapper.h"
#include "py3.h"
#include "server.h"
#include "common.h"

static inline void PyDict_ReplaceKey(PyObject *dict, PyObject *k1, PyObject *k2);

static http_parser_settings parser_settings;

static PyObject *IO_module;

Request *Request_new(ThreadInfo *thread_info, int client_fd, const char *client_addr) {
    Request *request = malloc(sizeof(Request));
    if (request == NULL){
        fprintf(stderr, "insufficient memory\n");
        exit(EXIT_FAILURE);
    }
#ifdef DEBUG
    static unsigned long request_id = 0;
    request->id = request_id++;
#endif
    request->thread_info = thread_info;
    request->client_fd = client_fd;
    request->client_addr = client_addr;
    request->is_final = 0;
    request->headers = NULL;
    BUFFER_INIT(request->io_buffer);
    http_parser_init((http_parser *) &request->parser, HTTP_REQUEST);
    http_parser_url_init(&request->parser.url_parser);
    request->parser.parser.data = request;
    Request_reset(request);
    return request;
}

/* Initialize Requests, or re-initialize for reuse on connection keep alive.
   Should not be called without `Request_clean` when `request->parser.field`
   can contain an object */
void Request_reset(Request *request) {
    memset(&request->state, 0, sizeof(Request) - (size_t) & ((Request *) NULL)->state);
    request->state.response_length_unknown = true;
    request->parser.last_call_was_header_value = true;
    request->parser.invalid_header = false;
    request->is_final = 0;
    request->headers = NULL;
    request->parser.field = NULL;
    request->thread_info->header_fields = 0;
    request->thread_info->payload_size = 0;
}

void Request_free(Request *request) {
    Request_clean(request);
    BUFFER_FREE(request->io_buffer);
    MAP_FREE(request->headers);
    free(request);
}

/* Close and DECREF all the Python objects in Request.
   Request_reset should be called after this if connection keep alive */
void Request_clean(Request *request) {
    if (request->iterable) {
        /* Call 'iterable.close()' if available */
        PyObject *close_method = PyObject_GetAttr(request->iterable, _close);
        if (close_method == NULL) {
            if (PyErr_ExceptionMatches(PyExc_AttributeError))
                PyErr_Clear();
        } else {
            PyObject_CallObject(close_method, NULL);
            Py_DECREF(close_method);
        }
        if (PyErr_Occurred()) PyErr_Print();
        Py_DECREF(request->iterable);
    }
    Py_XDECREF(request->iterator);
}

/* Parse stuff */
void Request_parse(Request *request, const char *data, const size_t data_len) {
    assert(data_len);
    http_parser_execute((http_parser *) &request->parser,
                        &parser_settings, data, data_len);
    if (request->parser.parser.http_major == 2) {
        request->state.error_code = HTTP_STATUS_HTTP_VERSION_NOT_SUPPORTED;
    }
    request->state.upgrade = request->parser.parser.upgrade;
}

#define REQUEST ((Request*)parser->data)
#define PARSER  ((bj_parser*)parser)
#define URL_PARSER  (((bj_parser*)parser)->url_parser)


static int
on_message_begin(http_parser *parser) {
    assert(PARSER->field == NULL);
    REQUEST->headers = PyDict_New();
    return 0;
}

static int
on_url(http_parser *parser, const char *path, size_t len) {
    if (*http_method_str(parser->method) != HTTP_CONNECT && http_parser_parse_url(path, len, 0, &URL_PARSER)) {
        REQUEST->state.error_code = HTTP_STATUS_BAD_REQUEST;
        return 1;
    }
    /*
     * Although officially there is no limit, many security configuration recommendations state that maxQueryStrings
     * on a server should be set to a maximum character limit of 1024 while the entire url including the query string
     * should be set to a max of 2048 characters
     * */
    if (len > 2048) {
        REQUEST->state.error_code = HTTP_STATUS_URI_TOO_LONG;
        return 1;
    }

    int query_part_len = 0;
    if (URL_PARSER.field_set & (1 << UF_QUERY)) {
        if (URL_PARSER.field_data[UF_QUERY].len > 1024) {
            REQUEST->state.error_code = HTTP_STATUS_URI_TOO_LONG;
            return 1;
        }
        char query_part[1024];
        memcpy(query_part, path + URL_PARSER.field_data[UF_QUERY].off, URL_PARSER.field_data[UF_QUERY].len);
        query_part[URL_PARSER.field_data[UF_QUERY].len] = '\0';
        MAP_SET_OR_APPEND(REQUEST->headers, (char *)(_QUERY_STRING), query_part);
        query_part_len = URL_PARSER.field_data[UF_QUERY].len;
    }

    int path_len = 2048 - query_part_len;
    if (URL_PARSER.field_set & (1 << UF_PATH)) {
        if (URL_PARSER.field_data[UF_PATH].len > path_len) {
            REQUEST->state.error_code = HTTP_STATUS_URI_TOO_LONG;
            return 1;
        }
        char path_part[path_len];
        memcpy(path_part, path + URL_PARSER.field_data[UF_PATH].off, URL_PARSER.field_data[UF_PATH].len);
        path_part[URL_PARSER.field_data[UF_PATH].len] = '\0';
        MAP_SET_OR_APPEND(REQUEST->headers, (char *)(_PATH_INFO), path_part);
    }

    return 0;
}

static int
on_header_field(http_parser *parser, const char *field, size_t len) {
    if (PARSER->last_call_was_header_value) {
        /* We are starting a new header */
        PARSER->field = "";
        PARSER->last_call_was_header_value = false;
        PARSER->invalid_header = false;
    }

    /* Header field size limit */
    if (len > SERVER_INFO->max_header_field_len) {
        REQUEST->state.error_code = HTTP_STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE;
        return 1;
    }

    /* Get field name */
    char field_processed[len];
    for (size_t i = 0; i < len; i++) {
        char c = field[i];
        if (c == '_') {
            // CVE-2015-0219
            PARSER->invalid_header = true;
        } else if (c == '-') {
            field_processed[i] = '_';
        } else if (c >= 'a' && c <= 'z') {
            field_processed[i] = c - ('a' - 'A');
        } else {
            field_processed[i] = c;
        }
    }

    /* Ignore invalid header */
    if (PARSER->invalid_header) {
        REQUEST->state.error_code = HTTP_STATUS_BAD_REQUEST;
        return 1;
    }

    field_processed[len] = '\0';

    /* Check if too many fields */
    if (REQUEST->thread_info->header_fields == SERVER_INFO->max_header_fields) {
        REQUEST->state.error_code = HTTP_STATUS_PAYLOAD_TOO_LARGE;
        return 1;
    } else {
        REQUEST->thread_info->header_fields++;
    }

    /* Append field name to the part we got from previous call */
    char *field_new = concat_str(PARSER->field, field_processed);
    if (strcmp(PARSER->field, ""))
        free(PARSER->field);
    if (field_new == NULL) {
        return 1;  // Memory likely to be exhausted
    }
    PARSER->field = field_new;

    return PARSER->field == NULL;
}

static int
on_header_value(http_parser *parser, const char *value, size_t len) {
    /*
     * HTTP does not define any limit. However most web servers do limit size of headers they accept.
     * For example in Apache default limit is 8KB, in IIS it's 16K.
     * Server will return 413 Entity Too Large error if headers size exceeds that limit.
     * */
    if (len > SERVER_INFO->max_header_field_len) {
        REQUEST->state.error_code = HTTP_STATUS_PAYLOAD_TOO_LARGE;
        return 1;
    }
    PARSER->last_call_was_header_value = true;
    char *http_new = concat_str("HTTP_", PARSER->field);
    if (http_new == NULL)
        return 1;  // Memory likely to be exhausted
    if (!PARSER->invalid_header) {
        /* Set header, or append data to header if this is not the first call */
        MAP_SET_OR_APPEND(REQUEST->headers, http_new, value);
    }
    free(http_new);

    /* If we are just keeping alive, make counter 0 */
    if (!strncmp("Keep-Alive", value, 10)) {
        REQUEST->thread_info->header_fields = 0;
    }
    return 0;
}

static int
on_body(http_parser *parser, const char *data, const size_t len) {
    if (REQUEST->is_final) {
        return 0;
    }
    if (REQUEST->thread_info->payload_size + len > SERVER_INFO->max_body_len) {
        REQUEST->state.error_code = HTTP_STATUS_PAYLOAD_TOO_LARGE;
        return 1;
    } else {
        REQUEST->thread_info->payload_size += len;
    }
    if (!REQUEST->io_buffer->size && !parser->content_length && !parser->http_minor &&
        !(parser->flags & F_CHUNKED)) {
        REQUEST->state.error_code = HTTP_STATUS_LENGTH_REQUIRED;
        return 1;
    }

    /* Write data to request buffer */
    BUFFER_PUSH(REQUEST->io_buffer, data, len);
    if (REQUEST->io_buffer == NULL) {
        return 1; // out of capacity
    }

    REQUEST->is_final = http_body_is_final(parser);

    return 0;

}

static int
on_message_complete(http_parser *parser) {

    /* SERVER_PROTOCOL (REQUEST_PROTOCOL) */
    MAP_SET(REQUEST->headers, _SERVER_PROTOCOL, parser->http_minor == 1 ? _HTTP_1_1 : _HTTP_1_0);

    /* REQUEST_METHOD */
    MAP_SET(REQUEST->headers, _REQUEST_METHOD, http_method_str(parser->method));

    /* REMOTE_ADDR */
    MAP_SET(REQUEST->headers, _REMOTE_ADDR, REQUEST->client_addr);

    /* HTTP_CONTENT_{LENGTH,TYPE} -> CONTENT_{LENGTH,TYPE} */
    KeyValuePair *item = MAP_GETITEM(REQUEST->headers, _HTTP_CONTENT_LENGTH);
    if (item != NULL)
        item->key = strdup(_CONTENT_LENGTH);
    item = MAP_GETITEM(REQUEST->headers, _HTTP_CONTENT_TYPE);
    if (item != NULL)
        item->key = strdup(_CONTENT_TYPE);

    REQUEST->state.parse_finished = true;

    return 0;
}

static inline void
PyDict_ReplaceKey(PyObject *dict, PyObject *old_key, PyObject *new_key) {
    PyObject *value = PyDict_GetItem(dict, old_key);
    if (value) {
        Py_INCREF(value);
        PyDict_DelItem(dict, old_key);
        PyDict_SetItem(dict, new_key, value);
        Py_DECREF(value);
    }
}


static http_parser_settings
        parser_settings = {
        on_message_begin, on_url, NULL, on_header_field,
        on_header_value, NULL, on_body, on_message_complete, NULL, NULL
};

