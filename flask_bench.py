from flask import Flask, request, jsonify
from werkzeug.exceptions import abort
import bjoern

app = Flask(__name__)


@app.route("/a/b/c", methods=("GET", "POST"))
def bench():
    if request.method == "GET":
        k = request.args.get("k")
        k2 = request.args.get("k2")

        return jsonify({"k": k, "k2": k2})
    elif request.method == "POST":
        k = request.args.get("k")
        k2 = request.args.get("k2")
        asdfghjkl = request.form["asdfghjkl"]

        return jsonify({"k": k, "k2": k2, "asdfghjkl": asdfghjkl})

    abort(400)


bjoern.run(app, "0.0.0.0", 8080, reuse_port=True)
