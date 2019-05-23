def test_bottle_app(bottle_app, client):
    response = client.get("/a/b/c?k=v&k2=v2'")
    assert response.status_code == 200
    assert response.reason == "OK"
    assert response.content == b"Hello, World! {'k': 'v', 'k2': \"v2'\"}"
    response = client.post("/a/b/c?k=v&k2=v2'", data={"k3": "v3", "k4": "v4"})
    assert response.status_code == 200
    assert response.reason == "OK"
    assert (
        response.content == b"Hello, World! "
        b"{'k': 'v', 'k2': \"v2'\", 'k3': 'v3', 'k4': 'v4'}"
        b" {'k3': 'v3', 'k4': 'v4'}"
    )
