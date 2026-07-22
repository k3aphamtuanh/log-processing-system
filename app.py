from http.server import BaseHTTPRequestHandler, HTTPServer

from pathlib import Path

import subprocess

import sys

PORT = 8000

BASE_DIR = Path(__file__).resolve().parent

SERVER_LOG_FILE = BASE_DIR / "server_log.txt"

MAIN_FILE = BASE_DIR / "main.py"

REPORT_FILE = BASE_DIR / "report.txt"

class Handler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path == "/health":

            self.send_response(200)

            self.end_headers()

            self.wfile.write(b"OK")

            return

        if self.path == "/report":

            with SERVER_LOG_FILE.open("rb") as f:

                subprocess.run([sys.executable, str(MAIN_FILE)], stdin=f, check=True, cwd=BASE_DIR,)

            report = REPORT_FILE.read_text(encoding="utf-8")

            self.send_response(200)

            self.end_headers()

            self.wfile.write(report.encode())

            return

        self.send_response(404)

        self.end_headers()

        self.wfile.write(b"Not Found")

HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
