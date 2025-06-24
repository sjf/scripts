#!/usr/bin/env bash
set -eu #x



for s in $(git stash list | cut -d: -f1); do
  echo $s
  git stash show $s
  echo
done


# FILE=$1
# for s in $(git stash list | cut -d: -f1); do
#   if [[ -n $(git stash show $s --name-only | grep "$FILE") ]]; then
#     echo $s
#     git stash show $s
#   fi
# done


# for b in $(git branch | grep sjf); do
#   if [[ -n $(git diff --name-only main..$b | grep "$FILE") ]]; then
#     echo == $b ==
#     git diff  main..$b -- "$FILE" | cat
#   fi
#   # git log  -- "$FILE"
#   # if git log $branch -- proto/build-protos.js | grep -q commit; then
#   #   echo $branch
#   #   git log $branch -p -- proto/build-protos.js
#   #   echo
#   # fi
# done
