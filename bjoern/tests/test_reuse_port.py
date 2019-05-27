import logging
import os
import signal
import time
from collections import defaultdict

import pytest
from bjoern.tests.conftest import _run_app

N_PROCESSES = 10
N_REQUESTS_PER_PROCESS = 100
N_REQUESTS = N_REQUESTS_PER_PROCESS * N_PROCESSES


@pytest.fixture()
def reuse_port_app():
    def app(environ, start_response):
        start_response("200 OK", [])
        return [b"Hello from process %d\n" % os.getpid()]

    processes = [
        _run_app(app, log_level=logging.INFO, reuse_port=True)
        for _ in range(3 * N_PROCESSES)
    ]

    time.sleep(0.5 * N_PROCESSES)

    try:
        yield processes
    finally:
        for proc in processes:
            os.kill(proc.pid, signal.SIGKILL)
        time.sleep(2)  # Should be enough for the server to stop


def test_reuse_port(reuse_port_app, client):
    responder_count = defaultdict(int)

    for i in range(N_REQUESTS):
        response = client.get("/")
        assert response.status_code == 200
        responder = response.content.split()[-1]
        responder_count[responder] += 1
    print(responder_count)
    for responder, count in responder_count.items():
        assert N_REQUESTS_PER_PROCESS * 0.7 < count < N_REQUESTS_PER_PROCESS * 1.2
