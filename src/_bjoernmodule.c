#include <Python.h>
#include <stdio.h>
#include "server.h"
#include "wsgi.h"
#include "filewrapper.h"
#include "log.h"
#include "py3.h"
#include "_bjoernmodule.h"


PyObject *
cffi_run(long socketfd,
         wchar_t *host,
         long port,
         PyObject *wsgi_app,
         long max_body_len,
         long max_header_fields,
         long max_header_field_len,
         long log_console_level,
         long log_file_level,
         wchar_t *file_log) {

    // Global information
    ServerInfo server_info;

    // Init global info
    server_info.max_body_len = max_body_len;
    server_info.max_header_fields = max_header_fields;
    server_info.max_header_field_len = max_header_field_len;
    server_info.wsgi_app = wsgi_app;

    // Set console logging
    switch (log_console_level) {
        case 0:
            log_set_console_level(LOG_TRACE);
            break;
        case 10:
            log_set_console_level(LOG_DEBUG);
            break;
        case 20:
            log_set_console_level(LOG_INFO);
            break;
        case 30:
            log_set_console_level(LOG_WARN);
            break;
        case 40:
            log_set_console_level(LOG_ERROR);
            break;
        case 50:
            log_set_console_level(LOG_FATAL);
            break;
        default:
            log_set_console_level(LOG_INFO);
            break;
    }
    server_info.log_console_level = log_console_level;
    log_info("ConsoleLogging level set to: %d", log_console_level);

    // Set file logging
    if (file_log > 0) {
        // Check if stdout/stderr
        server_info.log_file_level = log_file_level;
        if (!wcscmp(file_log, (wchar_t *) "-")) {
            // Check level
            FILE *_fd = fopen((char *) file_log, "w");
            log_set_fp(_fd);
            switch (log_file_level) {
                case 0:
                    log_set_file_level(LOG_TRACE);
                    break;
                case 10:
                    log_set_file_level(LOG_DEBUG);
                    break;
                case 20:
                    log_set_file_level(LOG_INFO);
                    break;
                case 30:
                    log_set_file_level(LOG_WARN);
                    break;
                case 40:
                    log_set_file_level(LOG_ERROR);
                    break;
                case 50:
                    log_set_file_level(LOG_FATAL);
                    break;
                default:
                    log_set_file_level(LOG_INFO);
                    break;
            }
            server_info.log_file_level = log_file_level;
            log_info("FileLogging level on %s set to: %d", file_log, log_file_level);
        } else {
            log_set_fp((FILE *) 0);
            log_info("FileLogging not set as it is stdout");
        }
    } else {
        log_info("No FileLogging set");
    }

    // Set socket
    if (socketfd < 0) {
        log_debug("Socket: Not a file descriptor");
        return
                NULL;
    }
    server_info.sockfd = socketfd;
    wcscpy(server_info.host, host);
    server_info.port = port;
    log_info("Socket bound: %d:%s:%ld", server_info.sockfd, server_info.host, server_info.port);

    // Action starts
    GIL_LOCK(0);
    _initialize_request_module(&server_info);
    GIL_UNLOCK(0);
    log_info("Request module initialized");

    server_run(&server_info);
    log_info("Bjoern listening at: %s:%ld", server_info.host, server_info.port);

    Py_RETURN_NONE;
}

static PyMethodDef Bjoern_FunctionTable[] = {
        {NULL, NULL, 0, NULL}
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
