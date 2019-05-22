def test_wsgi_204(wsgi_204_app, client):
    response = client.get("/")
    assert response.status_code == 204
    assert response.reason == "no content"
    assert response.content == b""
