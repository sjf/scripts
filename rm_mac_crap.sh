#!/bin/sh
set -eux
TIME=${1:-0}
find . -name ._\*  -type f -mmin +${TIME} -print0 | xargs -0 -r rm -v
