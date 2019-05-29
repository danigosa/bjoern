import json

import bjoern
from bottle import Bottle, request, response

app = Bottle(__name__)


@app.get("/a/b/c")
def bench_get():
    k = request.params.get("k")
    k2 = request.params.get("k2")

    response.content_type = "application/json"
    return json.dumps({"k": k, "k2": k2})


@app.post("/a/b/c")
def bench_post():
    k = request.params.get("k")
    k2 = request.params.get("k2")
    asdfghjkl = request.params["asdfghjkl"]
    image = request.form.get("image")

    response.content_type = "application/json"
    return json.dumps({"k": k, "k2": k2, "asdfghjkl": asdfghjkl, "image": image})


if __name__ == "__main__":
    bjoern.run(app, "0.0.0.0", 8080)
