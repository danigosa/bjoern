import os
import signal


def test_wsgi_signal(wsgi_signal_app, client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.reason == "ok"
    assert response.content == b"0 times"
    os.kill(wsgi_signal_app.pid, signal.SIGTERM)
    response = client.get("/")
    assert response.status_code == 200
    assert response.reason == "ok"
    assert response.content == b"1 times"
