import os
import signal
import time
import urllib

import requests_unixsocket
import pytest
import sys
from flask import Flask, request
from bjoern.tests.conftest import _run_app

UNIX_SOCKET = "/tmp/hello_world.sock"

session = requests_unixsocket.Session()


@pytest.fixture()
def unix_app():
    app = Flask(__name__)

    @app.route("/a/b/c", methods=("GET", "POST"))
    def hello_world():
        return "Hello, World! Args: {}".format(
            (
                request.args.get("k"),
                request.args.get("k2"),
                sorted(request.form.items()),
            )
        )

    if os.path.exists(UNIX_SOCKET):
        os.remove(UNIX_SOCKET)
    p = _run_app(app, host="unix:{}".format(UNIX_SOCKET), port=None)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.mark.skipif(sys.version_info == (3, 7), reason="requires python3.6")
def test_unix_app(unix_app):
    response = session.get(
        "http+unix://{}/a/b/c?k=v&k2=v2".format(urllib.parse.quote_plus(UNIX_SOCKET))
    )
    assert response.status_code == 200
    assert response.reason == "OK"
    assert response.content == b"Hello, World! Args: ('v', 'v2', [])"
    response = session.post(
        "http+unix://{}/a/b/c?k=v&k2=v2".format(urllib.parse.quote_plus(UNIX_SOCKET)),
        data={"k3": "v3", "k4": b"v4"},
    )
    assert response.status_code == 200
    assert response.reason == "OK"
    assert (
        response.content
        == b"Hello, World! Args: ('v', 'v2', [('k3', 'v3'), ('k4', 'v4')])"
    )
