#!/bin/bash
#set -x #print commands
set -u #fail for unset vars
set -e #exit on errors
egrep --line-buffered --color -i $@
