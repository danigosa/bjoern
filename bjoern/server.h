#ifndef __server_h__
#define __server_h__

#include "../http-parser/http_parser.h"

typedef struct {
  int sockfd;
  PyObject* wsgi_app;
  PyObject* host;
  PyObject* port;
  PyObject* log_level;
} ServerInfo;

void server_run(ServerInfo*);

#endif
