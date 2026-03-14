"""
Local server for Transgribator.
- Serves static files (transcriber.html)
- POST /extract-audio: accepts video, returns mp3 via ffmpeg

Usage: python server.py
Opens: http://localhost:8765
"""

import http.server
import subprocess
import tempfile
import os
import json
import shutil
import sys

PORT = 8765


def find_ffmpeg():
    found = shutil.which("ffmpeg")
    if found:
        return found
    local_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ffmpeg")
    if os.path.isdir(local_dir):
        for root, dirs, files in os.walk(local_dir):
            if "ffmpeg.exe" in files:
                return os.path.join(root, "ffmpeg.exe")
            if "ffmpeg" in files:
                return os.path.join(root, "ffmpeg")
    return None


FFMPEG = find_ffmpeg()


class Handler(http.server.SimpleHTTPRequestHandler):

    def do_POST(self):
        if self.path == "/extract-audio":
            self.handle_extract_audio()
        else:
            self.send_error(404)

    def handle_extract_audio(self):
        if not FFMPEG:
            self.send_json(500, {"error": "ffmpeg not found"})
            return

        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self.send_json(400, {"error": "Empty request"})
            return

        ext = self.headers.get("X-File-Extension", ".mp4")
        if not ext.startswith("."):
            ext = "." + ext

        tmp_in = None
        tmp_out_path = None
        try:
            tmp_in = tempfile.NamedTemporaryFile(suffix=ext, delete=False)
            remaining = content_length
            while remaining > 0:
                chunk = self.rfile.read(min(remaining, 1024 * 1024))
                if not chunk:
                    break
                tmp_in.write(chunk)
                remaining -= len(chunk)
            tmp_in.close()

            tmp_out_path = tmp_in.name + ".mp3"

            cmd = [
                FFMPEG, "-y",
                "-i", tmp_in.name,
                "-vn",
                "-acodec", "libmp3lame",
                "-ac", "1",
                "-ar", "16000",
                "-b:a", "64k",
                tmp_out_path
            ]

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600
            )

            if result.returncode != 0:
                err_msg = result.stderr[-500:] if result.stderr else "Unknown error"
                self.send_json(500, {"error": f"ffmpeg error: {err_msg}"})
                return

            if not os.path.exists(tmp_out_path):
                self.send_json(500, {"error": "ffmpeg produced no output"})
                return

            file_size = os.path.getsize(tmp_out_path)
            self.send_response(200)
            self.send_header("Content-Type", "audio/mpeg")
            self.send_header("Content-Length", str(file_size))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            with open(tmp_out_path, "rb") as f:
                while True:
                    chunk = f.read(1024 * 1024)
                    if not chunk:
                        break
                    self.wfile.write(chunk)

        except subprocess.TimeoutExpired:
            self.send_json(500, {"error": "ffmpeg timeout (>10 min)"})
        except Exception as e:
            self.send_json(500, {"error": str(e)})
        finally:
            if tmp_in and os.path.exists(tmp_in.name):
                os.unlink(tmp_in.name)
            if tmp_out_path and os.path.exists(tmp_out_path):
                os.unlink(tmp_out_path)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, X-File-Extension")
        self.end_headers()

    def send_json(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def log_message(self, format, *args):
        msg = format % args
        sys.stderr.write(f"[server] {msg}\n")


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    print(f"ffmpeg: {FFMPEG}")
    print(f"Server: http://localhost:{PORT}")
    print(f"Open:   http://localhost:{PORT}/transcriber.html")
    print("Ctrl+C to stop\n")
    server = http.server.HTTPServer(("", PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
