#!/bin/bash
set -eu

CONFIG=$HOME/scripts/.goaccess.conf
GEO_IP_DB=$HOME/scripts/.goaccess-geoip.mmdb

GOACCESS="goaccess --no-progress -p $CONFIG --geoip-database=$GEO_IP_DB --db-path=${TEMP_DIR} --ignore-crawlers"

# remove the non-error message in a subshell (to preserve the exit code)
# and redirects output back to stderr. Because this tool sucks.
$GOACCESS --persist -o ${DEST}/report_all.html ${TEMP_DIR}/access.log 2> >(grep -v 'Cleaning up resources...' >&2)

grep '" 404 ' ${TEMP_DIR}/access.log > ${TEMP_DIR}/access.404.log
$GOACCESS -o ${DEST}/report_404.html ${TEMP_DIR}/access.404.log 2> >(grep -v 'Cleaning up resources...' >&2)

grep '" 5[0-9][0-9] ' ${TEMP_DIR}/access.log > ${TEMP_DIR}/access.5xx.log
$GOACCESS -o ${DEST}/report_5xx.html ${TEMP_DIR}/access.5xx.log 2> >(grep -v 'Cleaning up resources...' >&2)

grep '" 200 ' ${TEMP_DIR}/access.log > ${TEMP_DIR}/access.200.log
$GOACCESS -o ${DEST}/report_200.html ${TEMP_DIR}/access.200.log 2> >(grep -v 'Cleaning up resources...' >&2)

cat $1 | egrep -v $(cat $SELF) > ${TEMP_DIR}/access.recent.log
$GOACCESS -o ${DEST}/report_recent.html ${TEMP_DIR}/access.recent.log 2> >(grep -v 'Cleaning up resources...' >&2)
