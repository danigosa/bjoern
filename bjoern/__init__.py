import logging
import os
import subprocess

__version__ = "4.0.10"
MAX_LISTEN_BACKLOG = int(
    subprocess.run(["cat", "/proc/sys/net/core/somaxconn"], stdout=subprocess.PIPE)
    .stdout.decode()
    .splitlines()[0]
)
DEFAULT_LISTEN_BACKLOG = MAX_LISTEN_BACKLOG // 2

DEFAULT_LOG_FILE = os.environ.get("BJOERN_LOG_FILE", "-")

DEFAULT_TCP_KEEPALIVE = bool(int(os.environ.get("BJOERN_SOCKET_TCP_KEEPALIVE", 1)))
DEFAULT_TCP_NODELAY = bool(int(os.environ.get("BJOERN_SOCKET_TCP_NODELAY", 1)))

DEFAULT_MAX_BODY_LEN = int(os.environ.get("BJOERN_SOCKET_MAX_BODY_LEN", 10490000000))

DEFAULT_MAX_FIELD_LEN = int(
    os.environ.get("BJOERN_SOCKET_MAX_FIELD_LEN", 8091)
)  # 10Mebibytes
DEFAULT_MAX_HEADER_FIELDS = int(os.environ.get("BJOERN_SOCKET_HEADER_FIELDS", 128))

DEFAULT_LOG_LEVEL = int(os.environ.get("BJOERN_LOG_LEVEL", logging.INFO))
DEFAULT_LOG_CONSOLE_LEVEL = int(
    os.environ.get("BJOERN_LOG_CONSOLE_LEVEL", DEFAULT_LOG_LEVEL)
)
DEFAULT_LOG_FILE_LEVEL = int(os.environ.get("BJOERN_LOG_FILE_LEVEL", DEFAULT_LOG_LEVEL))


def run(
    wsgi_app,
    host,
    port=None,
    log_console_level=DEFAULT_LOG_CONSOLE_LEVEL,
    log_file_level=DEFAULT_LOG_FILE_LEVEL,
    log_file=DEFAULT_LOG_FILE,
    reuse_port=False,
    listen_backlog=DEFAULT_LISTEN_BACKLOG,
    tcp_keepalive=DEFAULT_TCP_KEEPALIVE,
    tcp_nodelay=DEFAULT_TCP_NODELAY,
    fileno=None,
    max_body_len=DEFAULT_MAX_BODY_LEN,
    max_header_fields=DEFAULT_MAX_HEADER_FIELDS,
    max_header_field_len=DEFAULT_MAX_FIELD_LEN,
):
    from .server import run

    run(
        wsgi_app,
        host,
        port=port,
        log_console_level=log_console_level,
        log_file_level=log_file_level,
        log_file=log_file,
        reuse_port=reuse_port,
        listen_backlog=listen_backlog,
        tcp_keepalive=tcp_keepalive,
        tcp_nodelay=tcp_nodelay,
        fileno=fileno,
        max_body_len=max_body_len,
        max_header_fields=max_header_fields,
        max_header_field_len=max_header_field_len,
    )


def stop():
    from .server import stop

    stop()
