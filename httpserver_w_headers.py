#!/usr/bin/env python3

import sys
from http.server import SimpleHTTPRequestHandler, HTTPServer

class CustomHandler(SimpleHTTPRequestHandler):
  def end_headers(self):
    # self.extensions_map[''] = 'text/html'
    # print(self.headers, 'xxx',self.guess_type(self.path),type(self.guess_type(self.path)))
    if self.guess_type(self.path) == 'application/octet-stream':
      self.send_header('Content-Type', 'text/html')
    self.send_header('Cache-Control','no-store, no-cache, must-revalidate, max-age=0')
    super().end_headers()

port = 8081
if len(sys.argv) > 1:
  port = int(sys.argv[1])

server = HTTPServer(('0.0.0.0', port), CustomHandler)
print(f"Serving on port {port}...")
server.serve_forever()
