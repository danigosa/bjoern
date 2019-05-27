import logging
import os
import signal
import socket
import sys

import _bjoern
from bjoern import DEFAULT_LISTEN_BACKLOG

_default_instance = None
_sock = None
_wsgi_app = None

console_log = None
file_log = None


def bind_and_listen(
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    fileno=None,
):
    global _sock
    if fileno:
        sock = socket.socket(fileno=fileno)
    elif host.startswith("unix:@"):
        # Abstract UNIX socket: "unix:@foobar"
        sock = socket.socket(socket.AF_UNIX)
        sock.bind("\0" + host[6:])
    elif host.startswith("unix:"):
        # UNIX socket: "unix:/tmp/foobar.sock"
        sock = socket.socket(socket.AF_UNIX)
        sock.bind(host[5:])
    else:
        # IP socket
        sock = socket.socket(socket.AF_INET)
        # Set SO_REUSEADDR to make the IP address available for reuse
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if reuse_port:
            # Enable "receive steering" on FreeBSD and Linux >=3.9. This allows
            # multiple independent bjoerns to bind to the same port (and
            # ideally also set their CPU affinity), resulting in more efficient
            # load distribution.  https://lwn.net/Articles/542629/
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        sock.bind((host, int(port)))

    sock.listen(listen_backlog)
    _sock = sock
    return _sock


def server_run(sock, wsgi_app, *args):
    _bjoern.server_run(sock, wsgi_app, *args)


def setup_console_logging(log_level_):
    global console_log, log_console_level
    console_log = logging.getLogger(f"bjoern.console")
    console_log.setLevel(log_level_)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(log_level_)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    console_log.addHandler(handler)
    log_console_level = log_level_
    return console_log


def setup_file_logging(log_level_, log_file_):
    global file_log, log_file_level
    file_log = logging.getLogger(f"bjoern.file")
    file_log.setLevel(log_level_)

    handler = logging.FileHandler(log_file_)
    handler.setLevel(log_level_)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    file_log.addHandler(handler)
    log_file_level = log_level_
    return file_log


def listen(
    wsgi_app,
    host,
    port=None,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    fileno=None,
):
    """
    Makes bjoern listen to 'host:port' and use 'wsgi_app' as WSGI application.
    (This does not run the server mainloop.)

    'reuse_port' -- whether to set SO_REUSEPORT (if available on platform)
    'listen_backlog' -- listen backlog value (default: 1024)
    """
    global _default_instance, _wsgi_app, _sock
    if _default_instance:
        raise RuntimeError("Only one global server instance possible")
    _sock = bind_and_listen(
        host, port, reuse_port, listen_backlog=listen_backlog, fileno=fileno
    )
    if _wsgi_app is None:
        _wsgi_app = wsgi_app
    _default_instance = (_sock, _wsgi_app)
    return _default_instance


log_level = int(os.environ.get("BJ_LOG_LEVEL", logging.INFO))
log_console_level = int(os.environ.get("BJ_LOG_CONSOLE_LEVEL", log_level))
log_file_level = int(os.environ.get("BJ_LOG_FILE_LEVEL", log_level))
log_file = os.environ.get("BJ_LOG_FILE", "/var/log/bjoern.log")

setup_console_logging(log_console_level)
setup_file_logging(log_file_level, log_file)


def run(*args, **kwargs):
    """
    run(*args, **kwargs):
        Calls listen(*args, **kwargs) and starts the server mainloop.

    run():
        Starts the server mainloop. listen(...) has to be called before calling
        run() without arguments."
    """
    global _default_instance, console_log, file_log, log_console_level, log_file_level, log_file

    pid = os.getpid()
    uid = os.getuid()
    gid = os.getgid()
    if "fileno" in kwargs:
        args = [args[0], "fileno", kwargs["fileno"]]

    info = f"Booting Bjoern:\n"
    f"- host: {args[1]} \n"
    f"- port: {args[2]} \n"
    f"- LogConsoleLevel: {log_console_level} \n"
    f"- LogFileLevel: {log_file_level} \n"
    f"- LogToFile: {log_file}"
    f"- reuse_port: {kwargs.get('reusePort', False)} \n"
    f"- listen_backlog: {kwargs.get('listen_backlog', DEFAULT_LISTEN_BACKLOG)} \n"
    f"- pid: {pid} \n"
    f"- uid: {uid} \n"
    f"- gid: {gid} \n"

    _log_level = kwargs.pop(
        "log_level", int(os.environ.get("BJ_LOG_LEVEL", logging.INFO))
    )
    _log_console_level = kwargs.pop(
        "log_console_level", int(os.environ.get("BJ_LOG_CONSOLE_LEVEL", _log_level))
    )
    _log_file_level = kwargs.pop(
        "log_file_level", int(os.environ.get("BJ_LOG_FILE_LEVEL", _log_level))
    )
    _log_file = kwargs.pop(
        "log_file", os.environ.get("BJ_LOG_FILE", "/var/log/bjoern.log")
    )

    if console_log is None:
        console_log = setup_console_logging(_log_console_level)

    if file_log is None:
        file_log = setup_console_logging(_log_file_level)

    console_log.info(info)
    file_log.info(info)

    if args or kwargs:
        # Called as `bjoern.run(wsgi_app, host, ...)`
        _default_instance = listen(*args, **kwargs)
    else:
        # Called as `bjoern.run()`
        if not _default_instance:
            raise RuntimeError(
                "Must call bjoern.listen(wsgi_app, host, ...) "
                "before calling bjoern.run() without "
                "arguments."
            )
    sock, wsgi_app = _default_instance
    try:
        server_run(sock, wsgi_app, log_console_level, log_file_level, log_file)
    finally:
        if sock.family == socket.AF_UNIX:
            filename = sock.getsockname()
            if filename[0] != "\0":
                os.unlink(sock.getsockname())
        sock.close()
        _default_instance = None


def stop():
    global _default_instance, _sock, _wsgi_app, console_log, file_log, log_level, log_console_level, log_file_level, log_file
    pid = os.getpid()
    try:
        os.kill(pid, signal.SIGTERM)
    finally:
        os.kill(pid, signal.SIGKILL)
    _default_instance, _sock, _wsgi_app, console_log, file_log, log_level, log_console_level, log_file_level, log_file = (
        (None,) * 9
    )
