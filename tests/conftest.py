import json
import os
import signal
import sys
import time
from multiprocessing import Process
from wsgiref.validate import validator

import falcon
import pytest
import requests
from bottle import Bottle
from bottle import request as bottle_request
from flask import Flask
from flask import request as flask_request

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


@pytest.fixture
def client():
    return TestClient()


def _run_app(app):
    def _start_server(_app_):
        bjoern.run(_app_, "localhost", 8080)

    p = Process(target=_start_server, args=(app,))
    p.start()

    time.sleep(2)  # Should be enough for the server to start

    return p


@pytest.fixture()
def flask_app():
    app = Flask(__name__)

    @app.route("/a/b/c", methods=("GET", "POST"))
    def hello_world():
        return (
            f"Hello, World! Args:"
            f" {flask_request.args.get('k'), flask_request.args.get('k2'), dict(flask_request.form)}"
        )

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def bottle_app():
    app = Bottle()

    @app.get("/a/b/c")
    def hello():
        return f"Hello, World! {dict(bottle_request.params)}"

    @app.post("/a/b/c")
    def hello():
        return (
            f"Hello, World! {dict(bottle_request.params)} {dict(bottle_request.forms)}"
        )

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def falcon_app():
    class AppResource:
        def on_get(self, request, response):
            k = request.get_param("k")
            k2 = request.get_param("k2")

            response.status_code = 200
            response.content_type = "application/json"
            response.body = json.dumps({"k": k, "k2": k2})

        def on_post(self, request, response):
            k = request.get_param("k")
            k2 = request.get_param("k2")
            k3 = request.get_param("k3")
            k4 = request.get_param("k4")

            response.status_code = 200
            response.content_type = "application/json"
            response.body = json.dumps({"k": k, "k2": k2, "k3": k3, "k4": k4})

    app = falcon.API()
    app.req_options.auto_parse_form_urlencoded = True

    resource = AppResource()

    app.add_route("/a/b/c", resource)

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def exec_info_reference_app():
    _alist = []

    @validator
    def app(env, start_response):
        start_response("200 alright", [("Content-Type", "text/plain")])
        try:
            a
        except:
            import sys

            x = sys.exc_info()
            start_response("500 error", _alist, x)
        return [b"hello"]

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_compliance_app():
    @validator
    def app(environ, start_response):
        start_response("200 OK", [("Content-Type", "text/plain")])
        return [b"Hello, World!"]

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_headers_app():
    def app(env, start_response):
        start_response(
            "200 yo", [("Content-Type", "text/plain"), ("a" * 1000, "b" * 1000)]
        )
        return [b"foo", b"bar"]

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_204_app():
    @validator
    def app(e, s):
        s("204 no content", [])
        return []

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_empty_app():
    @validator
    def app(e, s):
        s("200 ok", [("Content-Type", "text/plain")])
        return [b""]

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_filewrapper_app():
    W = {
        "callable-iterator": lambda f, _: iter(lambda: f.read(64 * 1024), b""),
        "xreadlines": lambda f, _: f,
        "filewrapper": lambda f, env: env["wsgi.file_wrapper"](f),
        "filewrapper2": lambda f, env: env["wsgi.file_wrapper"](f, 1),
        "pseudo-file": lambda f, env: env["wsgi.file_wrapper"](PseudoFile()),
    }

    F = len(sys.argv) > 1 and sys.argv[1] or "README.rst"
    W = len(sys.argv) > 2 and W[sys.argv[2]] or W["filewrapper"]

    class PseudoFile:
        def read(self, *ignored):
            return b"ab"

    def app(env, start_response):
        f = open(F, "rb")
        wrapped = W(f, env)
        start_response("200 ok", [("Content-Length", str(os.path.getsize(F)))])
        return wrapped

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


@pytest.fixture()
def wsgi_signal_app():
    _n = 0

    def inc_counter(signum, frame):
        nonlocal _n
        _n += 1
        print("Increased counter to", _n)

    signal.signal(signal.SIGTERM, inc_counter)

    @validator
    def app(e, s):
        nonlocal _n
        s("200 ok", [("Content-Type", "text/plain")])
        return [b"%d times" % _n]

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop
