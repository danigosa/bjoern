def test_flask_app(flask_app, client):
    response = client.get("/a/b/c?k=v&k2=v2")
    assert response.status_code == 200
    assert response.reason == "OK"
    print(response.content)
    assert response.content == b"Hello, World! Args: ('v', 'v2', {})"
    response = client.post("/a/b/c?k=v&k2=v2", data={"k3": "v3", "k4": b"v4"})
    assert response.status_code == 200
    assert response.reason == "OK"
    print(response.content)
    assert (
        response.content == b"Hello, World! Args: ('v', 'v2', {'k3': 'v3', 'k4': 'v4'})"
    )
