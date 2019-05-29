import logging
import os
import signal
import socket
import sys

import _bjoern
from bjoern import (
    DEFAULT_KEEPALIVE,
    DEFAULT_LISTEN_BACKLOG,
    DEFAULT_LOG_CONSOLE_LEVEL,
    DEFAULT_LOG_FILE,
    DEFAULT_LOG_FILE_LEVEL,
    MAX_LISTEN_BACKLOG,
)

_default_instance = None


def bind_and_listen(
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    fileno=None,
    keepalive=None,
):
    if listen_backlog == 0:
        listen_backlog = MAX_LISTEN_BACKLOG

    sock = None
    if fileno is not None:
        # Socket is already bound and listening (gunicorn)
        sock = socket.socket(fileno=fileno)
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_DEFER_ACCEPT, 1)

    if sock is None and host.startswith("unix:@"):
        # Abstract UNIX socket: "unix:@foobar"
        sock = socket.socket(socket.AF_UNIX)
        sock.bind("\0" + host[6:])
    elif sock is None and host.startswith("unix:"):
        # UNIX socket: "unix:/tmp/foobar.sock"
        sock = socket.socket(socket.AF_UNIX)
        sock.bind(host[5:])
    else:
        # IP socket
        if sock is None:
            sock = socket.socket(socket.AF_INET)
        # Set SO_REUSEADDR to make the IP address available for reuse
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # Set TCP NODELAY
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

        if reuse_port:
            # Enable "receive steering" on FreeBSD and Linux >=3.9. This allows
            # multiple independent bjoerns to bind to the same port (and
            # ideally also set their CPU affinity), resulting in more efficient
            # load distribution.  https://lwn.net/Articles/542629/
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)

        if keepalive is not None:
            # Set socket keepalive
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, keepalive)

    if fileno is None:
        sock.bind((host, int(port)))

        sock.listen(listen_backlog)
    return sock


def server_run(sock, wsgi_app, *args):
    _bjoern.server_run(sock, wsgi_app, *args)


def setup_console_logging(log_level_):
    console_log = logging.getLogger(f"bjoern.console")
    console_log.setLevel(log_level_)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(log_level_)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    console_log.addHandler(handler)
    return console_log


def run(
    wsgi_app,
    host,
    port=None,
    log_console_level=DEFAULT_LOG_CONSOLE_LEVEL,
    log_file_level=DEFAULT_LOG_FILE_LEVEL,
    log_file=DEFAULT_LOG_FILE,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    keepalive=DEFAULT_KEEPALIVE,
    fileno=None,
):

    global _default_instance

    pid = os.getpid()
    uid = os.getuid()
    gid = os.getgid()

    console_log = setup_console_logging(log_console_level)

    file_log = setup_file_logging(log_file_level, log_file)

    info = (
        f"Booting Bjoern with params:\n"
        f"- host: {host} \n"
        f"- port: {port} \n"
        f"- LogConsoleLevel: {log_console_level} \n"
        f"- LogFileLevel: {log_file_level} \n"
        f"- LogToFile: {log_file}\n"
        f"- reuse_port: {reuse_port} \n"
        f"- listen_backlog: {listen_backlog} \n"
        f"- pid: {pid} \n"
        f"- uid: {uid} \n"
        f"- gid: {gid} \n"
        f"- keepalive: {keepalive} \n"
        f"- fd: {fileno} \n"
    )

    console_log.info(info)
    file_log.info(info) if file_log is not None else None

    # Call listen
    _default_instance = listen(
        wsgi_app,
        host,
        port=port,
        reuse_port=reuse_port,
        listen_backlog=DEFAULT_LISTEN_BACKLOG,
        fileno=fileno,
        keepalive=keepalive,
    )

    # Run WSGI server
    sock, wsgi_app = _default_instance
    try:
        server_run(sock, wsgi_app, log_console_level, log_file_level, file_log)
    finally:
        if sock.family == socket.AF_UNIX:
            filename = sock.getsockname()
            if filename[0] != "\0":
                os.unlink(sock.getsockname())
        sock.close()
        _default_instance = None


def setup_file_logging(log_level_, log_file_):
    file_log = logging.getLogger(f"bjoern.file")
    file_log.setLevel(log_level_)

    if log_file_ == "-" or log_file_ is None:
        return
    else:
        handler = logging.FileHandler(log_file_)
    handler.setLevel(log_level_)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    file_log.addHandler(handler)
    return file_log


def listen(
    wsgi_app,
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    fileno=None,
    keepalive=None,
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
    )
    _default_instance = (sock, wsgi_app)
    return _default_instance


def stop():
    global _default_instance, _sock, _wsgi_app
    pid = os.getpid()
    try:
        os.kill(pid, signal.SIGTERM)
    finally:
        os.kill(pid, signal.SIGKILL)
    _default_instance, _sock, _wsgi_app = (None,) * 3
