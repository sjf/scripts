#!/usr/bin/env python3
import sys
from transmission_rpc import Client
from transmission_rpc.error import TransmissionError

def exit(s):
	sys.stderr.write(str(s)+"\n")
	sys.exit(1)

HOST="192.168.0.5"
if len(sys.argv) < 3:
	exit("Usage <name> magnet_url [movie|tv]")

dirs = {'movie':'/home/sjf/share/Movies','tv':'/home/sjf/share/TV shows'}
url = sys.argv[1]
type_ = sys.argv[2]

if type_.lower() in ["movie","movies"]:
	dest = dirs["movie"]
elif type_.lower() in ["tv","episode","episodes"]:
	dest = dirs["tv"]
else:
	exit("Unrecognized type %s" % type_)

try:
	c = Client(host=HOST, port=9091, username="sjf", password="qwerty12")
	t = c.add_torrent(url, download_dir=dest)
	print(t)
except TransmissionError as e:
	#exit(e)
	print(e)
