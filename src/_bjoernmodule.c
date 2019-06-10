#include <Python.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include "server.h"
#include "wsgi.h"
#include "filewrapper.h"
#include "log.h"
#include "py3.h"
#include "_bjoernmodule.h"


char *slice_str(const char *str, size_t size, size_t start, size_t end) {
    char *buffer = malloc(sizeof(char[size]));
    size_t j = 0;
    for (size_t i = start; i <= end; ++i) {
        buffer[j++] = str[i];
    }
    buffer[j] = 0;
    return buffer;
}

// Global information
static ServerInfo *server_info = malloc(sizeof(ServerInfo));

PyObject *
cffi_run(int *socket,
         PyObject *wsgi_app,
         int max_body_len,
         int max_header_fields,
         int max_header_field_len,
         int log_console_level,
         int log_file_level,
         char *file_log) {

    // Init global info
    server_info->sockfd = socket;
    server_info->max_body_len = max_body_len;
    server_info->max_header_fields = max_header_fields;
    server_info->max_header_field_len = max_header_field_len;
    server_info->wsgi_app = wsgi_app;

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
    server_info->log_console_level = log_console_level;
    log_info("ConsoleLogging level set to: %d", log_console_level);

    // Set file logging
    if (file_log > 0) {
        // Check if stdout/stderr
        server_info->log_file_level = log_file_level;
        if (!strcmp(log_file_str, "-")) {
            // Check level
            FILE *_fd = fopen(log_file_str, "w");
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
            server_info->log_file_level = log_file_level;
            log_info("FileLogging level on %s set to: %d", log_file_str, log_file_level);
        } else {
            log_info("FileLogging not set as it is stdout");
        }
    } else {
        log_info("No FileLogging set");
    }

    // Get socket
    if (socket < 0) {
        log_debug("Socket: Not a file descriptor");
        return NULL;
    }
    server_info->sockfd = socket;
    unsigned int port;
    char host[16];
    struct sockaddr_in server_addr;
    bzero(&server_addr, sizeof(server_addr));
    int len = sizeof(server_addr);
    getsockname(sockfd, (struct sockaddr *) &server_addr, &len);
    inet_aton(my, &server_addr.sin_addr, host, sizeof(host));
    port = ntohs(server_addr.sin_port);
    strcpy(&server_info->host, host);
    server_info->port = port;
    log_info("Bjoern listening on: %s:%ud", server_info->host, server_info->port);

    // Action starts
    _initialize_request_module(&server_info);
    server_run(&server_info);

    Py_RETURN_NONE;
}

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
