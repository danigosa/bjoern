def test_flask_app_hello(flask_app_hello_app, client):
    response = client.get("/a/b/c?k=v&k2=v2")
    assert response.status_code == 200
    assert response.reason == "OK"
    assert (
        response.content
        == b"Hello, World! Args: ImmutableMultiDict([('k', 'v'), ('k2', 'v2')])"
    )
    response = client.post("/a/b/c?k=v&k2=v2", data={"k3": "v3"})
    assert response.status_code == 200
    assert response.reason == "OK"
    print(response.content)
    assert (
        response.content
        == b"Hello, World! Args: ImmutableMultiDict([('k', 'v'), ('k2', 'v2')])"
    )
