#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
#import urlparse

# HTTPRequestHandler class
class requestHandler(BaseHTTPRequestHandler):

  # GET
  def do_GET(self):
    #parsed_path = urlparse.urlparse(self.path)

    # Send response status code
    self.send_response(200)

    # Send headers
    self.send_header('Content-type','text/json')
    #self.send_header('')
    self.end_headers()

    # Send message back to client
    message = '{"auto_refresh":true,"injector_proxy":true,"ipfs_cache":false,"origin_access":true,"proxy_access":false, "ouinet_version": "1.23 345435af2340998ebc23409 12/34/2019 12:34:56Z release"}'
    # Write content as utf-8 data
    self.wfile.write(bytes(message, "utf8"))
    return

def run():
  print('starting server...')
  server_address = ('127.0.0.1', 8081)
  httpd = HTTPServer(server_address, requestHandler)
  print('running server...')
  httpd.serve_forever()

run()
