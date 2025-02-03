#!/bin/bash
set -e #exit on failed command
set -u #fail on undefined variable
set -x #print commands

mypy $@
python3 $@
