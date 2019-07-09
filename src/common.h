#ifndef __common_h__
#define __common_h__

#define PY_SSIZE_T_CLEAN

#include <Python.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <search.h>

#define TYPE_ERROR_INNER(what, expected, ...) \
  PyErr_Format(PyExc_TypeError, what " must be " expected " " __VA_ARGS__)
#define TYPE_ERROR(what, expected, got) \
  TYPE_ERROR_INNER(what, expected, "(got '%.200s' object instead)", Py_TYPE(got)->tp_name)

typedef struct {
    char *data;
    size_t len;
} string;

void _init_common(void);

char *concat_str(const char *s1, const char *s2);

PyObject *_REMOTE_ADDR, *_PATH_INFO, *_QUERY_STRING, *_REQUEST_METHOD, *_GET,
        *_HTTP_CONTENT_LENGTH, *_CONTENT_LENGTH, *_HTTP_CONTENT_TYPE,
        *_CONTENT_TYPE, *_SERVER_PROTOCOL, *_SERVER_NAME, *_SERVER_PORT,
        *_http, *_HTTP_, *_HTTP_1_1, *_HTTP_1_0, *_wsgi_input, *_close,
        *_empty_string, *_empty_bytes, *_BytesIO, *_write, *_read, *_seek;

#ifdef DEBUG
#define DBG_REQ(request, ...) \
    do { \
      DBG(__VA_ARGS__); \
    } while(0)
#define DBG(...) \
    do { \
    } while(0)
#else
#define DBG(...) do{}while(0)
#define DBG_REQ(...) DBG(__VA_ARGS__)
#endif

#define DBG_REFCOUNT(obj) \
  DBG(#obj "->obj_refcnt: %d", obj->ob_refcnt)

#define DBG_REFCOUNT_REQ(request, obj) \
  DBG_REQ(request, #obj "->ob_refcnt: %d", obj->ob_refcnt)

#ifdef WITHOUT_ASSERTS
#undef assert
#define assert(...) do{}while(0)
#endif


// Expandable BUFFER for io input/output
typedef struct {
    size_t size;
    size_t capacity;
    char *buffer;
} _Buffer;
#define BUFFER_CHUNK_SIZE 64*1024
#define BUFFER_INIT(data) \
    do { \
        _Buffer *buf = malloc(sizeof(_Buffer)); \
        if (buf != NULL)  { \
            buf->size = 0; \
            buf->capacity = BUFFER_CHUNK_SIZE; \
            buf->buffer = NULL; \
            data = buf; \
        } else { \
            fprintf(stderr, "insufficient memory\n"); \
            exit(EXIT_FAILURE); \
        } \
     } while(0)
#define BUFFER_FREE(buffer) \
    do { \
        if (buffer != NULL) { \
            free(buffer); \
            buffer = NULL; \
       } \
    } while(0)
#define BUFFER_PUSH(data, value, value_len) \
    do { \
       if (data->buffer == NULL) { \
            data->buffer = (char *) malloc(BUFFER_CHUNK_SIZE); \
            if (data->buffer == NULL) { \
                fprintf(stderr, "insufficient memory\n"); \
                exit(EXIT_FAILURE); \
            } \
            data->capacity = BUFFER_CHUNK_SIZE; \
       } \
       data->size += value_len; \
       if (data->size > data->capacity) { \
           data->capacity += 2 * data->capacity; \
           data->buffer = (char *) realloc(data->buffer, data->capacity); \
       } \
       if (data->buffer != NULL)  { \
          memcpy(data->buffer + data->size - value_len, value, value_len); \
       } else { \
            fprintf(stderr, "insufficient memory\n"); \
            exit(EXIT_FAILURE); \
       } \
    } while(0)

/* GIL */
#define GIL_LOCK(n) PyGILState_STATE _gilstate_##n = PyGILState_Ensure()
#define GIL_UNLOCK(n) PyGILState_Release(_gilstate_##n)

/* MAP */

// Binary Tree as C Map<str, str>
struct {
    char *key;
    char *value;
} KeyValuePair;
#define MAP_KEYCMP(a, b) \
    do { \
        const struct KeyValuePair *a = _a; \
        const struct KeyValuePair *b = _b; \
        return strcmp(a->key, b->key); \
    } while(0)
#define MAP_SET(root, key, value) \
    do { \
        KeyValuePair *np = malloc(sizeof(KeyValuePair)); \
        if (np == NULL) { \
            fprintf(stderr, "insufficient memory\n"); \
            exit(EXIT_FAILURE); \
        } \
        np->key = strdup(key); \
        np->value = strdup(value); \
        void *kvp = tfind(np, &root, MAP_KEYCMP); \
        if (kvp != NULL) { \
            kvp->value = strdup(value); \
            return kvp; \
        } else { \
            np = tsearch(np, &root, MAP_KEYCMP); \
            if (np == NULL) { \
                fprintf(stderr, "insufficient memory\n"); \
                exit(EXIT_FAILURE); \
            } \
            return np; \
        } \
     } while(0)
#define MAP_SET_OR_APPEND(root, key, value) \
    do { \
        KeyValuePair *np = malloc(sizeof(KeyValuePair)); \
        np->key = strdup(key); \
        np->value = strdup(value); \
        void *kvp = tfind(np, &root, MAP_KEYCMP); \
        if (kvp != NULL) { \
            kvp->value = concat_str(kvp->value, value); \
            return kvp; \
        } else { \
            np = tsearch(np, &root, MAP_KEYCMP); \
            if (np == NULL) { \
                fprintf(stderr, "insufficient memory\n"); \
                exit(EXIT_FAILURE); \
            } \
            return np; \
        } \
     } while(0)
#define MAP_FREE(root) \
    do { \
       tdestroy(root, free); \
    } while(0)
#define MAP_WALK(root, action) \
    do { \
       twalk(root, action); \
    } while(0)
#define MAP_GETITEM(root, key) \
    do { \
        KeyValuePair *np = malloc(sizeof(KeyValuePair)); \
        if (np == NULL) { \
            fprintf(stderr, "insufficient memory\n"); \
            exit(EXIT_FAILURE); \
        }  \
        np->key = strdup(key); \
        void *kvp = tfind(np, &root, MAP_KEYCMP); \
        if (kvp != NULL) \
            return kvp->value; \
        return NULL \
    } while(0)
/* End of module */
#endif