import json

from bottle import Bottle, request, response
import bjoern

app = Bottle(__name__)


@app.route("/a/b/c", method="GET")
def bench():
    k = request.args.get("k")
    k2 = request.args.get("k2")

    response.content_type = "application/json"
    return json.dumps({"k": k, "k2": k2})


@app.route("/a/b/c", method="POST")
def bench():
    k = request.args.get("k")
    k2 = request.args.get("k2")
    asdfghjkl = request.form["asdfghjkl"]
    response.content_type = "application/json"
    return json.dumps({"k": k, "k2": k2, "asdfghjkl": asdfghjkl})


bjoern.run(app, "0.0.0.0", 8080, reuse_port=True)
