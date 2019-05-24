import os
import signal
import time

import pytest

import bjoern
from tests.conftest import _run_app


@pytest.fixture()
def huge_app():
    N = 1024
    CHUNK = b"a" * 1024
    DATA_LEN = N * len(CHUNK)

    class _iter(object):
        def __iter__(self):
            for i in range(N):
                yield CHUNK

    def app(e, s):
        s("200 ok", [("Content-Length", str(DATA_LEN))])
        return _iter()

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


bjoern.run(app, "0.0.0.0", 8080)
