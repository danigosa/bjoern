def test_wsgi_compliance_app(wsgi_compliance_app, client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.reason == "OK"
    assert response.content == b"Hello, World!"
