import subprocess

__version__ = "4.0.6"
MAX_LISTEN_BACKLOG = int(
    subprocess.run(["cat", "/proc/sys/net/core/somaxconn"], stdout=subprocess.PIPE)
    .stdout.decode()
    .splitlines()[0]
)
DEFAULT_LISTEN_BACKLOG = MAX_LISTEN_BACKLOG // 2

DEFAULT_FILE_LOG = "-"


def run(*args, **kwargs):
    from .server import run

    run(*args, **kwargs)


def stop():
    from .server import stop

    stop()
