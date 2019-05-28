#include <Python.h>
#include <stdio.h>
#include "server.h"
#include "wsgi.h"
#include "filewrapper.h"
#include "log.h"
#include "py3.h"


char *slice_str(const char *str, size_t size, size_t start, size_t end) {
    char *buffer = malloc(sizeof(char[size]));
    size_t j = 0;
    for (size_t i = start; i <= end; ++i) {
        buffer[j++] = str[i];
    }
    buffer[j] = 0;
    return buffer;
}

static PyObject *
run(PyObject *self, PyObject *args) {
    ServerInfo info;

    PyObject *socket;

    PyObject *log_console_level;
    PyObject *log_file_level;
    PyObject *log_file;

    if (!PyArg_ParseTuple(args, "OOOOO:server_run", &socket, &info.wsgi_app, &log_console_level, &log_file_level,
                          &log_file)) {
        return NULL;
    }

    // Set console logging
    info.log_console_level = log_console_level;
    long l_console_level = PyLong_AsLong(info.log_console_level);
    int console_level = 0;
    switch (l_console_level) {
        case 0:
            console_level = LOG_TRACE;
            break;
        case 10:
            console_level = LOG_DEBUG;
            break;
        case 20:
            console_level = LOG_INFO;
            break;
        case 30:
            console_level = LOG_WARN;
            break;
        case 40:
            console_level = LOG_ERROR;
            break;
        case 50:
            console_level = LOG_FATAL;
            break;
        default:
            console_level = LOG_INFO;
            log_set_console_level(LOG_INFO);
            break;
    }
    log_set_console_level(console_level);
    log_info("ConsoleLogging level set to: %d", console_level * 10);

    // Set file logging
    info.log_file_level = log_file_level;
    long l_file_level = PyLong_AsLong(info.log_file_level);
    if (log_file != NULL) {
        if (strcmp(PyUnicode_AS_DATA(log_file), "-")) {
            info.log_file = stdout;
        } else {
            info.log_file = fopen(PyUnicode_AS_DATA(log_file), "w");
        }
        log_set_fp(info.log_file);
        int file_level = 0;
        switch (l_file_level) {
            case 0:
                file_level = LOG_TRACE;
                break;
            case 10:
                file_level = LOG_DEBUG;
                break;
            case 20:
                file_level = LOG_INFO;
                break;
            case 30:
                file_level = LOG_WARN;
                break;
            case 40:
                file_level = LOG_ERROR;
                break;
            case 50:
                file_level = LOG_FATAL;
                break;
            default:
                file_level = LOG_INFO;
                log_set_file_level(LOG_INFO);
                break;
        }
        log_set_file_level(file_level);
        log_info("FileLogging level set to: %d", file_level * 10);
    }

    // Check socket
    info.sockfd = PyObject_AsFileDescriptor(socket);
    if (info.sockfd < 0) {
        log_debug("Socket: Not a file descriptor");
        return NULL;
    }

    info.host = NULL;
    if (PyObject_HasAttrString(socket, "getsockname")) {
        PyObject *sockname = PyObject_CallMethod(socket, "getsockname", NULL);
        if (sockname == NULL) {
            log_debug("Socket: Bad socketname");
            return NULL;
        }
        if (PyTuple_CheckExact(sockname) && PyTuple_GET_SIZE(sockname) == 2) {
            /* Standard (ipaddress, port) case */
            info.host = PyTuple_GET_ITEM(sockname, 0);
            info.port = PyTuple_GET_ITEM(sockname, 1);
            log_debug("Socket IP host:post");
        }
    }
    PyObject *objectsRepresentation = PyObject_Repr(info.host);
    PyObject *str = PyUnicode_AsEncodedString(objectsRepresentation, "utf-8", "~E~");
    char *host = PyBytes_AS_STRING(str);
    char *fmt_host = slice_str(host, strlen(host), 1, strlen(host) - 2);
    log_info("Bjoern single-threaded started and listening on %.12s:%ld",
             fmt_host,
             PyLong_AsLong(info.port));
    Py_DECREF(objectsRepresentation);
    Py_DECREF(str);
    free(fmt_host);

    // Action starts
    _initialize_request_module(&info);
    server_run(&info);


    Py_RETURN_NONE;
}

static PyMethodDef Bjoern_FunctionTable[] = {
        {"server_run", (PyCFunction) run, METH_VARARGS, NULL},
        {NULL,         NULL,              0,            NULL}
};

static struct PyModuleDef module = {
        PyModuleDef_HEAD_INIT,
        "bjoern",
        NULL,
        -1, /* size of per-interpreter state of the module,
         or -1 if the module keeps state in global variables. */
        Bjoern_FunctionTable,
        NULL, NULL, NULL, NULL
};

#define INIT_BJOERN PyInit__bjoern


PyMODINIT_FUNC INIT_BJOERN(void) {
    _init_common();
    _init_filewrapper();

    PyType_Ready(&FileWrapper_Type);
    assert(FileWrapper_Type.tp_flags & Py_TPFLAGS_READY);
    PyType_Ready(&StartResponse_Type);
    assert(StartResponse_Type.tp_flags & Py_TPFLAGS_READY);
    Py_INCREF(&FileWrapper_Type);
    Py_INCREF(&StartResponse_Type);

    PyObject *bjoern_module = PyModule_Create(&module);
    if (bjoern_module == NULL) {
        return NULL;
    }

    return bjoern_module;
}
