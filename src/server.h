#ifndef __server_h__
#define __server_h__

#include <stdio.h>
#include <ev.h>

typedef struct {
    long sockfd;
    long max_body_len;
    long max_header_fields;
    long max_header_field_len;
    long port;
    long log_console_level;
    long log_file_level;
    long log_file;
    wchar_t *host;
    PyObject *wsgi_app;
} ServerInfo;

typedef struct {
    ServerInfo *server_info;
    ev_io accept_watcher;
    size_t payload_size;
    size_t header_fields;
} ThreadInfo;

void server_run(ServerInfo *);

#endif
