#!/usr/bin/env python3
# Serve a web export from THIS folder. Python 3 stdlib only.
#
#   python3 serve.py [port]        (default 8080)
#
# A plain static server is not quite enough for a wasm app:
#   - .wasm needs the application/wasm MIME type, or the browser cannot stream-compile it,
#   - COOP/COEP make the page cross-origin isolated, required whenever the build uses
#     SharedArrayBuffer and harmless when it does not,
#   - Cache-Control: no-store, because browsers cache a large .wasm HARD and a plain reload
#     then serves a stale build.
import http.server
import socketserver
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".data": "application/octet-stream",
        ".dpak": "application/octet-stream",
    }

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


class Server(socketserver.TCPServer):
    allow_reuse_address = True


with Server(("", PORT), Handler) as httpd:
    print(f"serving on http://localhost:{PORT}/")
    print(f"open   http://localhost:{PORT}/Samples.WebScene.Web.html")
    httpd.serve_forever()
