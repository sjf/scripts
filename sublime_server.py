#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import subprocess

mounts = {}

class RequestHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    try:
      url = urlparse(self.path)
      params = parse_qs(url.query)
      # print(params)
      if 'f' not in params:
        self.send("No param", 400)
        return

      remote_file = params['f'][0]
      local_file = get_local_path(remote_file)

      if local_file:
        open_sublime(local_file)
        code,content = 200, f"OK {local_file}"
      else:
        code,content = 404, f"No mount point for {remote_file}"

      self.send(content, code)
    except Exception as e:
      self.send(str(e), 500)
      raise e
      return

  def send(self, content, code=200):
    print(f"Response: {code} {content}")
    self.send_response(code)
    self.send_header('Content-type','text/plain')
    self.end_headers()
    self.wfile.write(bytes(content, "utf8"))

def get_mounts():
  cmd = "mount|grep sjf|grep box: | cut -d' ' -f1,3|sed 's|box:||'"
  output = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, text=True).stdout
  result = {}
  for l in output.split("\n"):
    if not l:
      continue
    parts = l.split(" ")
    result[parts[0]] = parts[1]
  for k,v in result.items():
    print(f"{k}:\t{v}")
  return result

def open_sublime(f):
  subprocess.run(f"/Users/sjf/scripts/sublime {f}", shell=True, check=True)

def get_local_path(f):
  for remote_prefix,local_prefix in mounts.items():
    if f.startswith(remote_prefix):
      return f.replace(remote_prefix, local_prefix)
  return None
  # raise Exception(f"Could not find mount point for {f}")

def run():
  global mounts
  mounts = get_mounts()

  server_address = ('0.0.0.0', 8000)
  print('starting server... http://%s:%d' % server_address)
  httpd = HTTPServer(server_address, RequestHandler)
  print('running server...')
  httpd.serve_forever()

run()
