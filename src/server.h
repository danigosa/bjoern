#ifndef __server_h__
#define __server_h__

#include <stdio.h>

typedef struct {
    int sockfd;
    PyObject *wsgi_app;
    PyObject *host;
    PyObject *port;
    PyObject *log_console_level;
    PyObject *log_file_level;
    PyObject *log_file;
    int log_file_fd;
} ServerInfo;

void server_run(ServerInfo *);

#endif
