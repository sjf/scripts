#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

content = """<!DOCTYPE html>
<html>
<head>
  <title>sjf home</title>
<!--   <meta http-equiv="refresh" content="5" /> -->
  <meta charset="utf-8">
</head>
<body>
<h1>sjf home</h1>
<a href='/out1.tar'>/out1.tar</a> 1.0M<p>
<a href='/out2.tar'>/out2.tar</a> 2.0M<p>
</body>
</html>"""

# HTTPRequestHandler class
class requestHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    path = urlparse(self.path).path
    print(path)
    if path == "/403":
      self.send_response(403)
      self.end_headers()
      return
    if path == '/ouinet':
      self.send_response(200)
      self.send_header('Content-type','text/html')
      self.send_header('X-Ouinet-Injection-ID', '10488c0b-d1ac-4225-b2c1-f051ad734665')
      self.send_header('X-Ouinet-Injection-Key', 'https://www.wikipedia.org/')
      self.send_header('X-Ouinet-Injection-Time', 'Wed, 17 Jul 2019 03:07:04')
      self.send_header('X-Ouinet-Insert-BEP44', 'ZDE6azMyOgFQU5nxh2EUr2F8cBeXyzNQiOoE7aEJ0+2pnRom6wuqNDpzYWx0MjA6cuZMq8I/m/EFTOorithxLNje0yszOnNlcWkxNTYzMzMyODI0MzM4ZTM6c2lnNjQ6Ufo/SU7ecJqfdeu5IK/Y4q3Bgb/MKwvEKTi037AbG+1Ncw0AWFFKSJxj5vukP5tp0ajNvFhLOPONReygeyaDCzE6djQzMTovemxpYi94nE2Q3W+bMBTF/xWP5xhsx3zU0h5Y+qWt2dYErd0UqTL4BqyAScCBZFX/95lM1fbgh+v7O1fnnFfvQ3vUBuzLAF2vW+MJMvPyVp1fam12nvAeG0V/P93dptntJ+ibRXKQX9Nh9XxY369W/LAbrrufYZm2i+qxs+DNvAqkcrr7LPseUJ8iRgj69mXTbcy1tCDQE6gZojH6fKzdjl4hMhckFoSju2U2YYvWWDAWZ+e9wy2cbFDZpp5Wa+icT4GakbIw9OGgpfLHxvm/CGVRAZ7kXVsL1ONGnmQJH5OIEzJDzbG3uINB1lo5J+5DnvC0n0eETPqbTJbOX7DxKLtSBIeJyuNCblkiudx4E/Ig3Y1lq/RWgxJo2RqXJfyXhTIRRoJH71l+yO4s0DNewwAOTYsC9hbfmMKdMOVEpKULGZKERpfpL7CSpoReoPxsof+/kwcwpa0EiiPGL56n50rXU+WU8CQpSI4VlQXmjIU4ZwXFWxJSqeI5j6LQsbZ37OQWkxjTOHvv32ecJ4T9csixqx1TWbvvRRCM4+iPeqf3oLT0264MvLc/aO+xh2U=')
      self.end_headers()
      self.wfile.write(bytes(content, "utf8"))
      return

    self.send_response(200)
    self.send_header('Content-type','text/json')
    self.end_headers()
    message = '{"auto_refresh":true,"injector_proxy":true,"ipfs_cache":false,"origin_access":true,"proxy_access":false, "ouinet_version": "1.23 345435af2340998ebc23409 12/34/2019 12:34:56Z release"}'
    # Write content as utf-8 data
    self.wfile.write(bytes(message, "utf8"))
    return

def run():
  server_address = ('0.0.0.0', 8081)
  print('starting server... http://%s:%d' % server_address)
  httpd = HTTPServer(server_address, requestHandler)
  print('running server...')
  httpd.serve_forever()

run()
