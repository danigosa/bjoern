import os
import sys

import bjoern
from gunicorn.glogging import Logger
from gunicorn.workers.base import Worker


class BjoernWorker(Worker):
    def __init__(self, *args, **kwargs):
        Worker.__init__(self, *args, **kwargs)

    def watchdog(self):
        self.notify()

        if self.ppid != os.getppid():
            self.log.info("Parent changed, shutting down: %s" % self)
            bjoern.stop()

    def run(self):
        bjoern.console_log = self.log
        bjoern.log_console_level = Logger.loglevel
        bjoern.file_console_level = Logger.loglevel
        bjoern.log_file = str(self.log.logfile)
        bjoern.run(
            self.wsgi,
            listen_backlog=self.cfg.worker_connections,
            fileno=self.sockets[0].fileno(),
        )

    def handle_quit(self, sig, frame):
        bjoern.stop()

    def handle_exit(self, sig, frame):
        bjoern.stop()
        sys.exit(0)
