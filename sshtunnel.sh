#!/bin/bash
#set -e #exit on failed command
#set -u #fail on undefined variable
set -x #print commands

F=/tmp/sshtunnel.log
HOST=oak.sjf.io
PORT=37099

if nc -v -z -w 1 192.168.0.5 22; then
  HOST=192.168.0.5
  PORT=22
fi

while :;do
  date
  ssh -p $PORT -o ExitOnForwardFailure=yes -N -L 9000:localhost:90 $HOST
  echo ----------------
  echo Sleeping...
  sleep 30s
done
