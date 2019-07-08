import logging
import os
import signal
import socket
import sys
import traceback

import _bjoern
from bjoern import (
    DEFAULT_LISTEN_BACKLOG,
    DEFAULT_MAX_BODY_LEN,
    DEFAULT_MAX_FIELD_LEN,
    DEFAULT_MAX_HEADER_FIELDS,
    DEFAULT_TCP_KEEPALIVE,
    DEFAULT_TCP_NODELAY,
    MAX_LISTEN_BACKLOG,
)

_default_instance = None


def bind_and_listen(
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    fileno=None,
    keepalive=DEFAULT_TCP_KEEPALIVE,
    tcp_nodelay=DEFAULT_TCP_NODELAY,
):
    if listen_backlog == 0:
        listen_backlog = MAX_LISTEN_BACKLOG

    sock = None
    if fileno is not None:
        # Socket is already bound and listening (gunicorn)
        sock = socket.socket(fileno=fileno)

    elif host.startswith("unix:@"):
        # Abstract UNIX socket: "unix:@foobar"
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.bind("\0" + host[6:])

    elif sock is None and host.startswith("unix:"):
        # UNIX socket: "unix:/tmp/foobar.sock"
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.bind(host[5:])

    else:
        # IP socket
        if sock is None:
            sock = socket.socket(socket.AF_INET)

        # Set SO_REUSEADDR to make the IP address available for reuse
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # Set TCP_DEFER_ACCEPT
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_DEFER_ACCEPT, 1)

        if tcp_nodelay:
            # Set TCP NODELAY
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

        if reuse_port:
            # Enable "receive steering" on FreeBSD and Linux >=3.9. This allows
            # multiple independent bjoerns to bind to the same port (and
            # ideally also set their CPU affinity), resulting in more efficient
            # load distribution.  https://lwn.net/Articles/542629/
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)

        if keepalive:
            # Set socket keepalive
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)

        sock.bind((host, int(port)))

    if fileno is None:
        sock.listen(listen_backlog)  # Only if no gunicorn

    return sock


def server_run(
    sockfd, host, port, wsgi_app, max_body_len, max_header_fields, max_header_field_len
):
    if isinstance(port, str):
        port = 0  # UNIX file socket has no port
    _bjoern.server_run(
        sockfd,
        host,
        port,
        wsgi_app,
        max_body_len,
        max_header_fields,
        max_header_field_len,
    )


def listen(
    wsgi_app,
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    fileno=None,
    keepalive=DEFAULT_TCP_KEEPALIVE,
    tcp_nodelay=DEFAULT_TCP_NODELAY,
):
    """
    Makes bjoern listen to 'host:port' and use 'wsgi_app' as WSGI application.
    (This does not run the server mainloop.)

    'reuse_port' -- whether to set SO_REUSEPORT (if available on platform)
    'listen_backlog' -- listen backlog value (default: 1024)
    """
    global _default_instance
    if _default_instance:
        raise RuntimeError("Only one global server instance possible")
    sock = bind_and_listen(
        host,
        port=port,
        reuse_port=reuse_port,
        listen_backlog=listen_backlog,
        fileno=fileno,
        keepalive=keepalive,
        tcp_nodelay=tcp_nodelay,
    )
    _default_instance = (sock, wsgi_app)
    return _default_instance


def run(
    wsgi_app,
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    tcp_keepalive=DEFAULT_TCP_KEEPALIVE,
    fileno=None,
    tcp_nodelay=DEFAULT_TCP_NODELAY,
    max_body_len=DEFAULT_MAX_BODY_LEN,
    max_header_fields=DEFAULT_MAX_HEADER_FIELDS,
    max_header_field_len=DEFAULT_MAX_FIELD_LEN,
):

    global _default_instance

    pid = os.getpid()
    uid = os.getuid()
    gid = os.getgid()

    info = (
        "Booting Bjoern with params:\n"
        "- WSGI: {} \n"
        "- host: {} \n"
        "- port: {} \n"
        "- reuse_port: {} \n"
        "- listen_backlog: {} \n"
        "- pid: {} \n"
        "- uid: {} \n"
        "- gid: {} \n"
        "- tcp_keepalive: {} \n"
        "- tcp_nodelay: {} \n"
        "- max_body_len: {} \n"
        "- max_header_fields: {} \n"
        "- max_header_field_len: {} \n"
        "- fd: {} \n"
        "- executable: {} \n"
    ).format(
        type(wsgi_app),
        host,
        port,
        reuse_port,
        listen_backlog,
        pid,
        uid,
        gid,
        tcp_keepalive,
        tcp_nodelay,
        max_body_len,
        max_header_fields,
        max_header_field_len,
        fileno,
        sys.executable,
    )
    logging.info(info)

    # Call listen
    _default_instance = listen(
        wsgi_app,
        host,
        port=port,
        reuse_port=reuse_port,
        listen_backlog=DEFAULT_LISTEN_BACKLOG,
        fileno=fileno,
        keepalive=tcp_keepalive,
        tcp_nodelay=tcp_nodelay,
    )

    # Run WSGI server
    sock, wsgi_app = _default_instance
    try:
        trace_on_abort()
        server_run(
            sock.fileno(),
            sock.getsockname()[0] if sock.getsockname()[0] is not None else "",
            sock.getsockname()[1] if sock.getsockname()[1] is not None else -1,
            wsgi_app,
            max_body_len,
            max_header_fields,
            max_header_field_len,
        )
    finally:
        if sock.family == socket.AF_UNIX:
            filename = sock.getsockname()
            if filename[0] != "\0":
                os.unlink(sock.getsockname())
        sock.shutdown(socket.SHUT_RDWR)
        sock.close()
        _default_instance = None


def trace_on_abort():
    def print_trace(sig, frame):
        trace = "".join(traceback.format_stack(frame))
        exec_info = sys.exc_info()
        print("Trace ABORT: \n{} \n{}".format(trace, exec_info))

    signal.signal(signal.SIGABRT, print_trace)


def stop():
    global _default_instance, _sock, _wsgi_app
    pid = os.getpid()
    try:
        os.kill(pid, signal.SIGTERM)
    finally:
        os.kill(pid, signal.SIGKILL)
    _default_instance, _sock, _wsgi_app = (None,) * 3
