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
    FILE *log_file;
} ServerInfo;

void server_run(ServerInfo *);

#endif
