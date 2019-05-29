import logging
import os
import subprocess

__version__ = "4.0.7"
MAX_LISTEN_BACKLOG = int(
    subprocess.run(["cat", "/proc/sys/net/core/somaxconn"], stdout=subprocess.PIPE)
    .stdout.decode()
    .splitlines()[0]
)
DEFAULT_LISTEN_BACKLOG = MAX_LISTEN_BACKLOG // 2

DEFAULT_LOG_FILE = os.environ.get("BJOERN_LOG_FILE", "-")

DEFAULT_KEEPALIVE = int(os.environ.get("BJOERN_KEEPALIVE", "3600"))

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
    keepalive=DEFAULT_KEEPALIVE,
    fileno=None,
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
        keepalive=keepalive,
        fileno=fileno,
    )


def stop():
    from .server import stop

    stop()
