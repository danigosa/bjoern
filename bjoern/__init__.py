__version__ = "4.0.6"
DEFAULT_LISTEN_BACKLOG = 2048


def run(*args, **kwargs):
    from .server import run

    run(*args, **kwargs)


def stop():
    from .server import stop

    stop()
