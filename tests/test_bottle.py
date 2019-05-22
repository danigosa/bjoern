def test_bottle_app_hello(bottle_app_hello_app, client):
    response = client.get("/hello")
    assert response.status_code == 200
    assert response.reason == "OK"
    assert response.content == b"Hello, World!"
