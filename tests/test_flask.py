#!/usr/bin/env python3
import time
from http import client as httplib
from multiprocessing import Process

from flask import Flask

import bjoern

app = Flask(__name__)


@app.route("/")
def hello_world():
    return "Hello, World!"


def _start_server():
    bjoern.run(app, "localhost", 8080, reuse_port=True)


def test_hello():
    p = Process(target=_start_server)
    p.start()

    time.sleep(3)  # Should be enough for the server to start
    try:
        h = httplib.HTTPConnection("localhost", 8080)
        h.request("GET", "/")
        response = h.getresponse()
    finally:
        p.terminate()

    assert response.reason == "OK"


if __name__ == "__main__":
    try:
        bjoern.run(app, "localhost", 8080, reuse_port=True)
    except AssertionError:
        print("Test failed")
    else:
        print("Test successful")


bjoern.run(app, "localhost", 8080)
