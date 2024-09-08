#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

HTML = """<!DOCTYPE html>
<html>
<head>
  <title>httpserver.py</title>
<!--   <meta http-equiv="refresh" content="5" /> -->
  <meta charset="utf-8">
<style>
  body {{
    font-family: Arial, Helvetica, sans-serif;
    font-size: 1.5rem;
  }}
  pre {{
      white-space: pre-wrap;
      word-wrap: break-word;
      font-size: 1.2rem;
  }}
</style>
</head>
<body>
<strong>Client IP:</strong> {ip} <br>
<strong>Request:</strong> {request}
<p>
Headers:

<pre>
{headers}
</pre>
</body>
</html>"""

CONTENT = """
"""

# HTTPRequestHandler class
class requestHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    path = urlparse(self.path).path
    if path == "/403":
      self.send_response(403)
      self.end_headers()
      return
    if path == '/favicon.ico':
      self.send_response(404)
      self.end_headers()
      return

    self.send_response(200)
    self.send_header('Content-type','text/html')
    # self.send_header('Content-type','text/json')
    self.end_headers()

    ip = self.client_address[0] # (ip,port)
    request = self.requestline
    headers = "\n".join([ f"{header}: {value}" for header,value in sorted(self.headers.items()) ])
    print()
    print(f"Client IP:{ip}")
    print(f"Request:{request}")
    print(f"Headers:\n{headers}")
    print("----------------------------")
    html = HTML.format(ip = ip, request = request, headers = headers)

    # Write content as utf-8 data
    self.wfile.write(bytes(html, "utf8"))
    return

def run():
  server_address = ('0.0.0.0', 8081)
  print('starting server... http://%s:%d' % server_address)
  httpd = HTTPServer(server_address, requestHandler)
  print('running server...')
  httpd.serve_forever()

run()
