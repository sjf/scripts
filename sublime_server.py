#!/usr/bin/env python3

import sys
import os
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import subprocess

class RequestHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    try:
      url = urlparse(self.path)
      params = parse_qs(url.query)
      # print(params)
      if 'f' not in params:
        self.send("No filename param", 400)
        return
      remote_file = params['f'][0]

      ip = self.client_address[0]
      print(f"Request from: {ip} '{remote_file}'")

      if ".." in remote_file:
        self.send(str("Filename rejected"), 500)
        return

      local_file = self.get_local_path(remote_file)

      if local_file:
        open_sublime(local_file)
        code,content = 200, f"OK {remote_file} -> {local_file}"
      else:
        code,content = 404, f"No mount point for {remote_file}"

      self.send(content, code)
    except Exception as e:
      self.send(str(e), 500)
      raise e
      return

  def get_local_path(self, f):
    mounts = get_mounts(self.server.remote_host)
    for remote_prefix,local_prefix in mounts.items():
      if f.startswith(remote_prefix):
        return f.replace(remote_prefix, local_prefix)
    return None
    # raise Exception(f"Could not find mount point for {f}")

  def send(self, content, code=200):
    print(f"Response: {code} {content}")
    self.send_response(code)
    self.send_header('Content-type','text/plain')
    self.end_headers()
    self.wfile.write(bytes(content+'\n', "utf8"))

def get_mounts(remote_host, show=False):
  cmd = f"mount|grep {remote_host}: | cut -d' ' -f1,3 | sed 's|{remote_host}:||'"
  output = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, text=True).stdout
  result = {}
  for l in output.split("\n"):
    if not l:
      continue
    remote_dir,local_dir = l.split(" ")
    result[remote_dir] = local_dir
  if show:
    for k,v in result.items():
      print(f"{k}: {v}")
  return result

def open_sublime(f):
  subprocess.run(f"/Users/sjf/scripts/sublime {f}", shell=True, check=True)

def start_tunnel(local_port, remote_host, remote_port):
  cmd = f"ssh -o ExitOnForwardFailure=yes  -N -R 127.0.0.1:{remote_port}:127.0.0.1:{local_port} {remote_host}"
  print(cmd)
  try:
    subprocess.run(cmd, shell=True, check=True)
  except subprocess.CalledProcessError as e:
    print(e)
    os._exit(0)

def bind_from_string(s):
  parts = s.split(":")
  if len(parts) != 2:
    raise Exception(f"Expected format host:port, got '{s}'")
  return parts[0], parts[1]

def run():
  local_host, local_port = '127.0.0.1', 8000
  remote_host, remote_port = 'box', 3456
  if len(sys.argv) > 1:
    try:
      local_host, local_port = bind_from_string(sys.argv[1])
      if len(sys.argv) > 2:
        remote_host, remote_port = bind_from_string(sys.argv[2])
    except Exception as e:
      print("Usage: {sys.argv[0]} local_address:local_port [remote_host:remote_port]")
      raise e

  get_mounts(remote_host, show=True)

  bind = (local_host, local_port)
  print('starting server... http://%s:%d' % bind)
  httpd = HTTPServer(bind, RequestHandler)
  httpd.remote_host = remote_host
  print('running server...')
  serving = threading.Thread(target=httpd.serve_forever)
  # serving.daemon = True
  serving.start()

  if remote_host:
    local_port = bind[1]
    tunnel = threading.Thread(target=lambda:start_tunnel(local_port, remote_host, remote_port))
    # tunnel.daemon = True
    tunnel.start()

run()
