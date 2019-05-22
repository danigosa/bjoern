import os
import signal
import time
from multiprocessing import Process
from wsgiref.validate import validator

import pytest
import requests
from bottle import Bottle
from flask import Flask, request

import bjoern


class TestClient:
    base_url: str = "http://127.0.0.1:8080"

    def get(self, path="/", params=None, token=None, headers=None, **kwargs):
        _headers = {}

        if token:
            _headers["Authorization"] = f"Bearer {token}"

        if headers is not None:
            _headers.update(headers)

        if params and len(params):
            uri_params = "&".join([k + "=" + str(v) for k, v in params.items()])
            path = f"{path}?{uri_params}"

        return requests.get(f"{self.base_url}{path}", headers=_headers, **kwargs)

    def post(self, path="/", json=None, data=None, headers=None):
        headers_ = {}

        if json is not None:
            data = json.dumps(json)
            headers_["Content-Type"] = "application/json"

        if headers is not None:
            headers_.update(headers)

        return requests.post(f"{self.base_url}{path}", data=data, headers=headers_)


def flask_hello():
    app = Flask(__name__)

    @app.route("/a/b/c", methods=("GET", "POST"))
    def hello_world():
        return f"Hello, World! Args: {request.args.get('k'), request.args.get('k2'), dict(request.form)}"

    return app


def bottle_hello():
    app = Bottle()

    @app.route("/hello")
    def hello():
        return "Hello, World!"

    return app


def wsgi_hello():
    @validator
    def _app(environ, start_response):
        start_response("200 OK", [("Content-Type", "text/plain")])
        return [b"Hello, World!"]

    return _app


def wsgi_204():
    @validator
    def _app(e, s):
        s("204 no content", [])
        return []

    return _app


def wsgi_empty():
    @validator
    def _app(e, s):
        s("200 ok", [("Content-Type", "text/plain")])
        return [b""]

    return _app


def wsgi_signal():
    _n = 0

    def inc_counter(signum, frame):
        nonlocal _n
        _n += 1
        print("Increased counter to", _n)

    signal.signal(signal.SIGTERM, inc_counter)

    @validator
    def _app(e, s):
        nonlocal _n
        s("200 ok", [("Content-Type", "text/plain")])
        return [b"%d times" % _n]

    return _app


def wsgi_exec_info():
    _alist = []

    @validator
    def _app(env, start_response):
        start_response("200 alright", [("Content-Type", "text/plain")])
        try:
            a
        except:
            import sys

            x = sys.exc_info()
            start_response("500 error", _alist, x)
        return [b"hello"]

    return _app


@pytest.fixture
def client():
    return TestClient()


@pytest.fixture()
def flask_app_hello_app():
    _app = flask_hello()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def bottle_app_hello_app():
    _app = bottle_hello()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_hello_app():
    _app = wsgi_hello()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_204_app():
    _app = wsgi_204()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_empty_app():
    _app = wsgi_empty()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_signal_app():
    _app = wsgi_signal()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_exec_info_app():
    _app = wsgi_exec_info()

    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(_app,))
    p.start()

    time.sleep(5)  # Should be enough for the server to start

    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop
