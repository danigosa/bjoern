import base64
import os
import signal
import time

import pytest
from flask import Flask, jsonify, request
from bjoern.tests.conftest import _run_app

with open("bjoern/tests/charlie.jpg", "rb") as f:
    raw_data = f.read()
    data = base64.b64encode(raw_data).decode("utf-8")


@pytest.fixture()
def json_app_in():
    app = Flask(__name__)

    @app.route("/image", methods=("POST",))
    def bas64_json():
        return jsonify({"data": request.get_json()["data"]})

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


def test_json_app_in(json_app_in, client):
    for i in range(100):
        response = client.post("/image", json={"data": data})
        assert response.status_code == 200
        assert response.reason == "OK"
        assert response.json()["data"] == data
        assert base64.b64decode(response.json()["data"].encode()) == raw_data
