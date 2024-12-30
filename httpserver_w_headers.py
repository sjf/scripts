#!/usr/bin/env python3

import sys
from http.server import SimpleHTTPRequestHandler, HTTPServer

class CustomHandler(SimpleHTTPRequestHandler):
  def end_headers(self):
    self.send_header('Content-Type', 'text/html')
    super().end_headers()

port = 8081
if len(sys.argv) > 1:
  port = int(sys.argv[1])

server = HTTPServer(('0.0.0.0', port), CustomHandler)
print(f"Serving on port {port}...")
server.serve_forever()
