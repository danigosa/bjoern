#ifndef __server_h__
#define __server_h__

#include <stdio.h>
#include <ev.h>

typedef struct {
    int sockfd;
    int max_body_len;
    int max_header_fields;
    int max_header_field_len;
    int port;
    int log_console_level;
    int log_file_level;
    int log_file;
    char * host;
    PyObject * wsgi_app;
} ServerInfo;

typedef struct {
    ServerInfo *server_info;
    ev_io accept_watcher;
    size_t payload_size;
    size_t header_fields;
} ThreadInfo;

void server_run(ServerInfo *);

#endif
