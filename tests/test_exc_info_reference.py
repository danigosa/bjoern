def test_wsgi_exec_info(exec_info_reference_app, client):
    response = client.get("/")
    assert response.status_code == 500
    assert response.reason == "Internal Server Error"
    assert response.content == b""
