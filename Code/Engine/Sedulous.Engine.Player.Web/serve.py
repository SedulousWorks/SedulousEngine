#!/usr/bin/env python3
# Serve a web export from THIS folder. Python 3 stdlib only (and openssl for --https).
#
#   python3 serve.py [port]                  (default 8000)  ->  http://localhost:8000/
#   python3 serve.py [port] --https          the same over HTTPS, for another device on the network
#   python3 serve.py [port] --cert C --key K HTTPS with your own certificate
#
# A plain static server is not quite enough for a wasm app:
#   - .wasm needs the application/wasm MIME type (streaming compile),
#   - COOP/COEP headers make the page cross-origin isolated (required whenever the build
#     uses SharedArrayBuffer; harmless otherwise),
#   - Cache-Control: no-store, because browsers cache the large .wasm/.pak HARD and a
#     plain reload often serves a stale build.
#
# WebGPU exists only in a secure context: a page from localhost, or over HTTPS. Opened from
# another machine by this one's address over plain HTTP, the page loads but has no WebGPU and the
# game cannot start. --https serves it securely with a self-signed certificate (made once with
# openssl, kept beside this script as serve-cert.pem / serve-key.pem): the browser warns the first
# time; accept it (Advanced, then Continue) and the page is a secure context.
import argparse
import http.server
import os
import socket
import socketserver
import ssl
import subprocess
import sys

parser = argparse.ArgumentParser(description="Serve a web export from this folder.")
parser.add_argument("port", nargs="?", type=int, default=8000)
parser.add_argument("--https", action="store_true", help="serve over HTTPS with a self-signed certificate")
parser.add_argument("--cert", help="a certificate (PEM) for HTTPS")
parser.add_argument("--key", help="the certificate's private key (PEM)")
args = parser.parse_args()


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".pak": "application/octet-stream",
        ".dpak": "application/octet-stream",
    }

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def self_signed(directory):
    """The certificate --https serves, made once with openssl and kept beside this script."""
    cert = os.path.join(directory, "serve-cert.pem")
    key = os.path.join(directory, "serve-key.pem")
    if not (os.path.exists(cert) and os.path.exists(key)):
        print("making a self-signed certificate (serve-cert.pem, serve-key.pem)")
        subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "825",
                        "-subj", "/CN=web export", "-keyout", key, "-out", cert],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return cert, key


def addresses():
    """This machine's addresses on the network, for the other devices to open."""
    found = set()
    try:
        probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        probe.connect(("192.0.2.1", 9))  # no packet is sent; it picks the outward interface
        found.add(probe.getsockname()[0])
        probe.close()
    except OSError:
        pass
    return sorted(found)


secure = args.https or (args.cert and args.key)
with Server(("", args.port), Handler) as httpd:
    if secure:
        cert, key = (args.cert, args.key) if args.cert and args.key else self_signed(
            os.path.dirname(os.path.abspath(__file__)))
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(cert, key)
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    scheme = "https" if secure else "http"
    pages = sorted(name for name in os.listdir(".") if name.endswith(".html"))
    page = pages[0] if pages else ""
    print(f"serving this folder on port {args.port} (Ctrl+C to stop)")
    print(f"  here:  {scheme}://localhost:{args.port}/{page}")
    for address in addresses():
        print(f"  from another device: {scheme}://{address}:{args.port}/{page}")
    if not secure:
        print("  (WebGPU needs HTTPS from another device: run with --https)")
    sys.stdout.flush()
    httpd.serve_forever()
