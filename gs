#!/bin/bash
set -e #exit on failed command
set -u #fail on undefined variable
#set -x #print commands

if [ -f tools/go.work.sum ]; then
  git restore tools/go.work.sum
fi

git status
