#!/bin/bash
set -e #exit on failed command
set -u #fail on undefined variable

. ~/scripts/git-utils
. ~/scripts/log-utils.sh
#set -x
if [[ -z "$REPO" ]]; then
  err Not in a git repo
  exit 1
fi
if [[ "$REPO" == "${MONOREPO:-}" ]]; then
  info Not showing uptracked files
  git status
else
  git status -uno
fi


