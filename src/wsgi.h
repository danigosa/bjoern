#include <Python.h>
#include "request.h"

bool wsgi_call_application(Request*);
PyObject* wsgi_iterable_get_next_chunk(Request*);
PyObject* wrap_http_chunk_cruft_around(PyObject* chunk);
void initialize_request_module();
void action(const void *nodep, VISIT which, int depth);
PyTypeObject StartResponse_Type;
