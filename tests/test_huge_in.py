import base64
import os
import signal
import time

import pytest

from tests.conftest import _run_app

# with open("tests/charlie.jpg", "rb") as f:
#     image_bytes = f.read()
# data = base64.encodebytes(image_bytes)
data = b"a" * 1024 * 1024
DATA_LEN = len(data)


@pytest.fixture()
def huge_app_in():
    def app(e, s):
        s("200 ok", [("Content-Length", str(DATA_LEN))])
        return []

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


def test_huge_app_in(huge_app_in, client):
    response = client.post("/image", data={"data": data})
    assert response.status_code == 200
    assert response.reason == "ok"
    assert response.headers["Content-Length"] == str(DATA_LEN)
