import os
import socket
import sys

from gunicorn.workers.base import Worker

import bjoern


class BjoernWorker(Worker):
    def __init__(self, *args, **kwargs):
        Worker.__init__(self, *args, **kwargs)

    def watchdog(self):
        self.notify()

        if self.ppid != os.getppid():
            self.log.info("Parent changed, shutting down: %s" % self)
            bjoern.stop()

    def run(self):
        bjoern.log_file = self.log.logfile
        sckt = self.sockets[0]
        if sckt.FAMILY == socket.AF_INET:
            (host, port) = sckt.sock.getsockname()
        elif sckt.FAMILY == socket.AF_UNIX:
            host = str(sckt.sock.getsockname())
            port = -1
        else:
            raise RuntimeError("Invalid socket for worker")

        bjoern.run(
            self.wsgi,
            host,
            port,
            reuse_port=True,
            listen_backlog=self.cfg.worker_connections,
            log_console_level=self.log.error_log.level,
            log_file_level=self.log.error_log.level,
            log_file=self.log.logfile,
            fileno=sckt.sock.fileno(),
        )

    def handle_quit(self, sig, frame):
        bjoern.stop()

    def handle_exit(self, sig, frame):
        bjoern.stop()
        sys.exit(0)
