"""HTTP interface for the log processing tool."""

from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import subprocess
import sys

PORT = 8000
REPORT_TIMEOUT_SECONDS = 30

BASE_DIR = Path(__file__).resolve().parent
SERVER_LOG_FILE = BASE_DIR / "server_log.txt"
MAIN_FILE = BASE_DIR / "main.py"
REPORT_FILE = BASE_DIR / "report.txt"


class Handler(BaseHTTPRequestHandler):
    def send_text(self, status, text):
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self.send_text(200, "OK")
            return

        if self.path != "/report":
            self.send_text(404, "Not Found")
            return

        try:
            with SERVER_LOG_FILE.open("rb") as log_file:
                subprocess.run(
                    [sys.executable, str(MAIN_FILE)],
                    stdin=log_file,
                    check=True,
                    cwd=BASE_DIR,
                    timeout=REPORT_TIMEOUT_SECONDS,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.PIPE,
                )

            report = REPORT_FILE.read_text(encoding="utf-8")

        except subprocess.TimeoutExpired:
            self.log_error("Report generation exceeded %s seconds", REPORT_TIMEOUT_SECONDS)
            self.send_text(504, "Report generation timed out")
            return

        except subprocess.CalledProcessError as error:
            self.log_error("Report generation failed with exit code %s", error.returncode)
            self.send_text(500, "Report generation failed")
            return

        except (OSError, UnicodeError) as error:
            self.log_error("Report file or process error: %s", error)
            self.send_text(500, "Report generation failed")
            return

        self.send_text(200, report)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
