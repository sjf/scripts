#!/bin/bash
#set -x #print commands
#set -e #exit on failed command
set -u #fail on undefined variable

echo Starting
echo $(date)
SRC=/Users/sjf/Downloads/done
F=$SRC/complete_torrents.txt
TARGET=/Volumes/pismb
date > $F
set -e
rsync -a --stats --progress $SRC/* $TARGET
set +e
echo Finished
echo $(date)
echo '****************************************'