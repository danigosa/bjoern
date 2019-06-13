from cffi import FFI

ffibuilder = FFI()


ffibuilder.cdef(
    """
void * server_run_cffi(long socketfd,
                   wchar_t *host,
                   long port,
                   void *wsgi_app,
                   long max_body_len,
                   long max_header_fields,
                   long max_header_field_len,
                   long log_console_level,
                   long log_file_level,
                   wchar_t *file_log);
"""
)

libs = [
    "/bjoern/build/_bjoernmodule.o",
    "/bjoern/build/request.o",
    "/bjoern/build/filewrapper.o",
    "/bjoern/build/portable_sendfile.o",
    "/bjoern/build/common.o",
    "/bjoern/build/server.o",
    "/bjoern/build/log.o",
    "/bjoern/build/wsgi.o",
    "/bjoern/vendors/http-parser/http_parser.o",
    "/bjoern/vendors/http-parser/url_parser",
]
includes = ["/bjoern/src"]
ffibuilder.set_source(
    "_bjoern_cffi",
    """
    #include <Python.h>
    #include <_bjoernmodule.h>
    
    PyObject * server_run_cffi(long socketfd,
                   wchar_t *host,
                   long port,
                   void *wsgi_app,
                   long max_body_len,
                   long max_header_fields,
                   long max_header_field_len,
                   long log_console_level,
                   long log_file_level,
                   wchar_t *file_log) {           
        return cffi_run(socketfd,
                      host, 
                      port, 
                      (PyObject*)wsgi_app, 
                      max_body_len, 
                      max_header_fields, 
                      max_header_field_len,
                      log_console_level,
                      log_file_level,
                      file_log);
    }
    """,
    libraries=["c", "ev"],
    extra_objects=libs,
    include_dirs=includes,
)  # library name, for the linker

if __name__ == "__main__":
    ffibuilder.compile(verbose=True)
