import os
import sys

import bjoern
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
        bjoern.log_file = self.log.logfile
        bjoern.run(
            self.wsgi,
            listen_backlog=self.cfg.worker_connections,
            log_level=self.log.access.level,
            console_log_level=self.log.access.level,
            file_log_level=self.log.error.level,
            file_log=self.log.logfile,
            fileno=self.sockets[0].fileno(),
        )

    def handle_quit(self, sig, frame):
        bjoern.stop()

    def handle_exit(self, sig, frame):
        bjoern.stop()
        sys.exit(0)
