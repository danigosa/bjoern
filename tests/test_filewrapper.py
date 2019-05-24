import os
import signal
import sys
import time

import pytest

from tests.conftest import _run_app

f = (
    b"bjoern: Fast And Ultra-Lightweight HTTP/1.1 WSGI Server for Python3.6+\n======================================="
    b"================================\n\n.. image:: https://badges.gitter.im/Join%20Chat.svg\n   :alt: Join the chat"
    b" at https://gitter.im/jonashaag/bjoern\n   :target: https://gitter.im/jonashaag/bjoern?utm_source=badge&utm_med"
    b"ium=badge&utm_campaign=pr-badge&utm_content=badge\n\nA screamingly fast, ultra-lightweight WSGI_ server for CPy"
    b"thon3.6+,\nwritten in C using Marc Lehmann's high performance libev_ event loop and\nRyan Dahl's http-parser_."
    b"\n\nFor those looking for CPython2 or CPython3.4 or CPython3.5, please use Bjoern 3.x.\n\nWhy It's Cool\n~~~~~~"
    b"~~~~~~~\nbjoern is the *fastest*, *smallest* and *most lightweight* WSGI server out there,\nfeaturing\n\n* ~ 10"
    b"00 lines of C code\n* Memory footprint ~ 600KB\n* Python 2 and Python 3 support (thanks @yanghao!)\n* Single-th"
    b"readed and without coroutines or other crap\n* Can bind to TCP `host:port` addresses and Unix sockets (thanks @"
    b'k3d3!)\n* Full persistent connection ("*keep-alive*") support in both HTTP/1.0 and 1.1,\n  including support '
    b"for HTTP/1.1 chunked responses\n\nInstallation\n~~~~~~~~~~~~\n``pip install bjoern``. See `wiki <https://github"
    b".com/jonashaag/bjoern/wiki/Installation>`_ for details.\n\nUsage\n~~~~~\n::\n\n   # Bind to TCP host/port pair:"
    b"\n   bjoern.run(wsgi_application, host, port)\n\n   # TCP host/port pair, enabling SO_REUSEPORT if available."
    b"\n   bjoern.run(wsgi_application, host, port, reuse_port=True)\n\n   # Bind to Unix socket:\n   bjoern.run(wsgi"
    b"_application, 'unix:/path/to/socket')\n\n   # Bind to abstract Unix socket: (Linux only)\n   bjoern.run(wsgi_ap"
    b"plication, 'unix:@socket_name')\n\nAlternatively, the mainloop can be run separately::\n\n   bjoern.listen(wsgi"
    b"_application, host, port)\n   bjoern.run()\n   \nYou can also simply pass a Python socket(-like) object. Note t"
    b"hat you are responsible\nfor initializing and cleaning up the socket in that case. ::\n\n   bjoern.server_run(s"
    b"ocket_object, wsgi_application)\n   bjoern.server_run(filedescriptor_as_integer, wsgi_application)\n\n.. _WSGI:"
    b"         http://www.python.org/dev/peps/pep-0333/\n.. _libev:        http://software.schmorp.de/pkg/libev.html"
    b"\n.. _http-parser:  https://github.com/joyent/http-parser\n"
)


@pytest.fixture()
def wsgi_filewrapper_app():
    W = {
        "callable-iterator": lambda f, _: iter(lambda: f.read(64 * 1024), b""),
        "xreadlines": lambda f, _: f,
        "filewrapper": lambda f, env: env["wsgi.file_wrapper"](f),
        "filewrapper2": lambda f, env: env["wsgi.file_wrapper"](f, 1),
        "pseudo-file": lambda f, env: env["wsgi.file_wrapper"](PseudoFile()),
    }

    F = len(sys.argv) > 1 and sys.argv[1] or "README.rst"
    W = len(sys.argv) > 2 and W[sys.argv[2]] or W["filewrapper"]

    class PseudoFile:
        def read(self, *ignored):
            return b"ab"

    def app(env, start_response):
        f = open(F, "rb")
        wrapped = W(f, env)
        start_response("200 ok", [("Content-Length", str(os.path.getsize(F)))])
        return wrapped

    p = _run_app(app)
    try:
        yield p
    finally:
        os.kill(p.pid, signal.SIGKILL)
        time.sleep(1)  # Should be enough for the server to stop


def test_wsgi_filewrapper_app(wsgi_filewrapper_app, client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.reason == "ok"
    assert response.content == f
    assert response.headers["Content-Length"] == str(len(f))
