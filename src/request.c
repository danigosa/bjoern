#include <Python.h>
#include <string.h>
#include "request.h"
#include "filewrapper.h"
#include "py3.h"
#include "log.h"

static inline void PyDict_ReplaceKey(PyObject *dict, PyObject *k1, PyObject *k2);

static http_parser_settings parser_settings;
static PyObject *wsgi_base_dict = NULL;

static PyObject *IO_module;

Request *Request_new(ServerInfo *server_info, int client_fd, const char *client_addr) {
    Request *request = malloc(sizeof(Request));
#ifdef DEBUG
    static unsigned long request_id = 0;
    request->id = request_id++;
#endif
    request->server_info = server_info;
    request->client_fd = client_fd;
    request->client_addr = _PEP3333_String_FromUTF8String(client_addr);
    request->is_final = 0;
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
    request->parser.field = NULL;
}

void Request_free(Request *request) {
    Request_clean(request);
    Py_DECREF(request->client_addr);
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
    Py_XDECREF(request->headers);
    Py_XDECREF(request->status);
    Py_XDECREF(request->parser.field);
}

/* Parse stuff */
void Request_parse(Request *request, const char *data, const size_t data_len) {
    assert(data_len);
    size_t nparsed = http_parser_execute((http_parser *) &request->parser,
                                         &parser_settings, data, data_len);
    if (nparsed != data_len){
        log_error("Bad length(%zu != %zu): BAD REQUEST", nparsed, data_len);
        request->state.error_code = HTTP_STATUS_BAD_REQUEST;
    if (request->parser.parser.http_major == 2){
        log_error("HTTP2 not supported: VERSION NOT SUPPORTED", nparsed, data_len);
        request->state.error_code = HTTP_STATUS_HTTP_VERSION_NOT_SUPPORTED;
    }
    request->state.upgrade = request->parser.parser.upgrade;
}

#define REQUEST ((Request*)parser->data)
#define PARSER  ((bj_parser*)parser)
#define URL_PARSER  (((bj_parser*)parser)->url_parser)

#define _set_header(k, v) PyDict_SetItem(REQUEST->headers, k, v);

/* PyDict_SetItem() increases the ref-count for value */
#define _set_header_free_value(k, v) \
  do { \
    PyObject* val = (v); \
    _set_header(k, val); \
    Py_DECREF(val); \
  } while(0)

static void
_set_or_append_header(PyObject *headers, PyObject *k, const char *val, size_t len) {
    PyObject *py_val = _PEP3333_String_FromLatin1StringAndSize(val, len);
    PyObject *py_val_old = PyDict_GetItem(headers, k);

    if (py_val_old) {
        PyObject *py_val_new = _PEP3333_String_Concat(py_val_old, py_val);
        PyDict_SetItem(headers, k, py_val_new);
        Py_DECREF(py_val_new);
    } else {
        PyDict_SetItem(headers, k, py_val);
    }
    Py_DECREF(py_val);
}

static int
on_message_begin(http_parser *parser) {
    assert(PARSER->field == NULL);
    REQUEST->headers = PyDict_New();
    return 0;
}

static int
on_url(http_parser *parser, const char *path, size_t len) {
    if (*http_method_str(parser->method) != HTTP_CONNECT && http_parser_parse_url(path, len, 0, &URL_PARSER)) {
        log_error("Failed to parse URL: (%zu) %s", len, path);
        return 1;
    }
    if (len > 512) {
        log_error("URL is to long: %zu", len);
        return 1;
    }
    char path_part[512];

    if (URL_PARSER.field_set & (1 << UF_PATH)) {
        memcpy(path_part, path + URL_PARSER.field_data[UF_PATH].off, URL_PARSER.field_data[UF_PATH].len);
        path_part[URL_PARSER.field_data[UF_PATH].len] = '\0';
        _set_or_append_header(REQUEST->headers, _PATH_INFO, path_part, URL_PARSER.field_data[UF_PATH].len);
    }

    char query_part[512];

    if (URL_PARSER.field_set & (1 << UF_QUERY)) {
        memcpy(query_part, path + URL_PARSER.field_data[UF_QUERY].off, URL_PARSER.field_data[UF_QUERY].len);
        query_part[URL_PARSER.field_data[UF_QUERY].len] = '\0';
        _set_or_append_header(REQUEST->headers, _QUERY_STRING, query_part, URL_PARSER.field_data[UF_QUERY].len);
    }

    return 0;
}

static int
on_header_field(http_parser *parser, const char *field, size_t len) {
    if (PARSER->last_call_was_header_value) {
        /* We are starting a new header */
        Py_XDECREF(PARSER->field);
        Py_INCREF(_HTTP_);
        PARSER->field = _HTTP_;
        PARSER->last_call_was_header_value = false;
        PARSER->invalid_header = false;
    }

    /* Ignore invalid header */
    if (PARSER->invalid_header) {
        return 0;
    }
    char field_processed[len];
    for (size_t i = 0; i < len; i++) {
        char c = field[i];
        if (c == '_') {
            // CVE-2015-0219
            PARSER->invalid_header = true;
            return 0;
        } else if (c == '-') {
            field_processed[i] = '_';
        } else if (c >= 'a' && c <= 'z') {
            field_processed[i] = c - ('a' - 'A');
        } else {
            field_processed[i] = c;
        }
    }

    /* Append field name to the part we got from previous call */
    PyObject *field_old = PARSER->field;
    PyObject *field_new = _PEP3333_String_FromLatin1StringAndSize(field_processed, len);
    PARSER->field = _PEP3333_String_Concat(field_old, field_new);
    Py_DECREF(field_old);
    Py_DECREF(field_new);

    return PARSER->field == NULL;
}

static int
on_header_value(http_parser *parser, const char *value, size_t len) {
    PARSER->last_call_was_header_value = true;
    if (!PARSER->invalid_header) {
        /* Set header, or append data to header if this is not the first call */
        _set_or_append_header(REQUEST->headers, PARSER->field, value, len);
    }
    return 0;
}

static int
on_body(http_parser *parser, const char *data, const size_t len) {
    if (REQUEST->is_final) {
        log_debug("Body is Final(%zu)", len);
        return 0;
    }

    log_debug("Body(%zu)", len);
    PyObject *body;
    body = PyDict_GetItem(REQUEST->headers, _wsgi_input);
    if (body == NULL) {
        if (!parser->content_length && !parser->http_minor && !(parser->flags & F_CHUNKED)) {
            REQUEST->state.error_code = HTTP_STATUS_LENGTH_REQUIRED;
            log_error("Bad Body Length(%zu:%zu):\n%s", parser->content_length, len, data);
            return 1;
        }
        body = PyObject_CallMethodObjArgs(IO_module, _BytesIO, NULL);
        if (body == NULL) {
            log_error("Bad Body from IO_module(%zu):\n%s", len, data);
            return 1;
        }
        _set_header_free_value(_wsgi_input, body);
    }

    PyObject *temp_data = _PEP3333_Bytes_FromStringAndSize(data, len);
    PyObject *tmp = PyObject_CallMethodObjArgs(body, _write, temp_data, NULL);
    if (PyErr_Occurred()) PyErr_Print();

    Py_DECREF(tmp); /* Never throw away return objects from py-api */
    Py_DECREF(temp_data);
    REQUEST->is_final = http_body_is_final(parser);
    log_debug("Is body final?; %d", REQUEST->is_final);
    return 0;
}

static int
on_message_complete(http_parser *parser) {
    /* HTTP_CONTENT_{LENGTH,TYPE} -> CONTENT_{LENGTH,TYPE} */
    PyDict_ReplaceKey(REQUEST->headers, _HTTP_CONTENT_LENGTH, _CONTENT_LENGTH);
    PyDict_ReplaceKey(REQUEST->headers, _HTTP_CONTENT_TYPE, _CONTENT_TYPE);

    /* SERVER_PROTOCOL (REQUEST_PROTOCOL) */
    _set_header(_SERVER_PROTOCOL, parser->http_minor == 1 ? _HTTP_1_1 : _HTTP_1_0);

    /* REQUEST_METHOD */
    if (parser->method == HTTP_GET) {
        /* I love useless micro-optimizations. */
        _set_header(_REQUEST_METHOD, _GET);
    } else {
        _set_header_free_value(_REQUEST_METHOD,
                               _PEP3333_String_FromUTF8String(http_method_str(parser->method))
        );
    }

    /* REMOTE_ADDR */
    _set_header(_REMOTE_ADDR, REQUEST->client_addr);

    PyObject *body = PyDict_GetItem(REQUEST->headers, _wsgi_input);
    if (body) {
        /* first do a seek(0) and then read() returns all data */
        log_debug("on_message_complete: request has body and we seek to 0 [%s, HTTP1.%d %d]",
                  http_method_str(parser->method), parser->http_minor, REQUEST->state.error_code);
        PyObject *buf = PyObject_CallMethodObjArgs(body, _seek, _FromLong(0), NULL);
        Py_DECREF(buf); /* Discard the return value */
    } else {
        /* Request has no body */
        log_debug("on_message_complete: request has no body [%s, HTTP1.%d %d]",
                  http_method_str(parser->method), parser->http_minor, REQUEST->state.error_code);
        body = PyObject_CallMethodObjArgs(IO_module, _BytesIO, NULL);
        _set_header_free_value(_wsgi_input, body);
    }

    PyDict_Update(REQUEST->headers, wsgi_base_dict);

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

void _initialize_request_module(ServerInfo *server_info) {
    IO_module = PyImport_ImportModule("io");
    if (IO_module == NULL) {
        /* PyImport_ImportModule should have exception set already */
        return;
    }

    if (wsgi_base_dict == NULL) {
        wsgi_base_dict = PyDict_New();

        /* dct['wsgi.file_wrapper'] = FileWrapper */
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.file_wrapper",
                (PyObject * ) & FileWrapper_Type
        );

        /* dct['SCRIPT_NAME'] = '' */
        PyDict_SetItemString(
                wsgi_base_dict,
                "SCRIPT_NAME",
                _empty_string
        );

        /* dct['wsgi.version'] = (1, 0) */
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.version",
                PyTuple_Pack(2, _FromLong(1), _FromLong(0))
        );

        /* dct['wsgi.url_scheme'] = 'http'
         * (This can be hard-coded as there is no TLS support in bjoern.) */
        Py_INCREF(_http);
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.url_scheme",
                _http
        );

        /* dct['wsgi.errors'] = sys.stderr */
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.errors",
                PySys_GetObject("stderr")
        );

        /* dct['wsgi.multithread'] = False
         * (Tell the application that it is being run
         *  in a single-threaded environment.) */
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.multithread",
                Py_False
        );

        /* dct['wsgi.multiprocess'] = True
         * (Tell the application that it is being run
         *  in a multi-process environment.) */
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.multiprocess",
                Py_True
        );

        /* dct['wsgi.run_once'] = False
         * (bjoern is no CGI gateway) */
        PyDict_SetItemString(
                wsgi_base_dict,
                "wsgi.run_once",
                Py_False
        );

        /* dct['SERVER_NAME'] = '...'
         * dct['SERVER_PORT'] = '...'
         * Both are required by WSGI specs. */
        if (server_info->host) {
            PyDict_SetItemString(wsgi_base_dict, "SERVER_NAME", server_info->host);

            if (server_info->port == Py_None) {
                PyDict_SetItemString(wsgi_base_dict, "SERVER_PORT", PyUnicode_FromFormat(""));
            } else {
                PyDict_SetItemString(wsgi_base_dict, "SERVER_PORT", PyUnicode_FromFormat("%i", server_info->port));
            }
        } else {
            /* SERVER_NAME is required, but not usefull with UNIX type sockets */
            PyDict_SetItemString(wsgi_base_dict, "SERVER_NAME", PyUnicode_FromFormat(""));
            PyDict_SetItemString(wsgi_base_dict, "SERVER_PORT", PyUnicode_FromFormat(""));
        }
    }
}
