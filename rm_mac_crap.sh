#!/bin/sh
set -eux
TIME=${1:-0}
for dir in ~/mb ~/sbb ~/sjf ~/scripts;do
  find $dir -name ._\*  -type f -mmin +${TIME} -print0 | xargs -0 -r rm -v
done
