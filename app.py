from http.server import BaseHTTPRequestHandler, HTTPServer

from pathlib import Path

import subprocess

import sys

PORT = 8000

class Handler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path == "/health":

            self.send_response(200)

            self.end_headers()

            self.wfile.write(b"OK")

            return

        if self.path == "/report":

            with open("server_log.txt", "rb") as f:

                subprocess.run([sys.executable, "main.py"], stdin=f, check=True)

            report = Path("report.txt").read_text()

            self.send_response(200)

            self.end_headers()

            self.wfile.write(report.encode())

            return

        self.send_response(404)

        self.end_headers()

        self.wfile.write(b"Not Found")

HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
