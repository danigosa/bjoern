import os
import sys

import bjoern
from gunicorn.glogging import Logger
from gunicorn.workers.base import Worker


class BjoernWorker(Worker):
    def __init__(self, *args, **kwargs):
        Worker.__init__(self, *args, **kwargs)

        if bjoern.file_log is not None:
            Logger.error = bjoern.file_log
            bjoern.file_log = self.log

    def watchdog(self):
        self.notify()

        if self.ppid != os.getppid():
            self.log.info("Parent changed, shutting down: %s" % self)
            bjoern.stop()

    def run(self):

        # We catch the first, just one UNIX socket is allowed
        if self.sockets:
            sock = self.sockets[0]
            bjoern._sock = sock

        bjoern.run(self.wsgi)

    def handle_quit(self, sig, frame):
        bjoern.stop()

    def handle_exit(self, sig, frame):
        bjoern.stop()
        sys.exit(0)
