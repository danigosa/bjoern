def test_wsgi_empty(wsgi_empty_app, client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.reason == "ok"
    assert response.content == b""
