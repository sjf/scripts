#!/bin/bash
set -eu

if [[ ${1:-} == '-v' ]]; then
  set -x
  shift
fi

LOG_FILES="$@"
DEST=${DEST:-.}
CONFIG=$HOME/scripts/.goaccess.conf
GEO_IP_DB=$HOME/scripts/.goaccess-geoip.mmdb
SELF=$HOME/sjf/self.txt

TEMP_DIR=$(mktemp -d /tmp/goaccess.XXXX)
mkdir -p $TEMP_DIR

GOACCESS="goaccess --no-progress -p $CONFIG --geoip-database=$GEO_IP_DB --db-path=${TEMP_DIR}"

# Remove internal requests
if [ -f $SELF ]; then
  zcat -f $LOG_FILES | egrep -v $(cat $SELF) > ${TEMP_DIR}/access.log
else
  zcat -f $LOG_FILES > ${TEMP_DIR}/access.log
fi

# Remove automated tests
grep -v python-requests/sjfsjfsjf ${TEMP_DIR}/access.log > ${TEMP_DIR}/access.log.1 || true
mv ${TEMP_DIR}/access.log.1 ${TEMP_DIR}/access.log

# remove the non-error message in a subshell (to preserve the exit code)
# and redirects output back to stderr. Because this tool sucks.
$GOACCESS --persist -o ${DEST}/report_all.html ${TEMP_DIR}/access.log 2> >(grep -v 'Cleaning up resources...' >&2)

# $GOACCESS --restore -o ${DEST}/report.html \
#   --ignore-panel=NOT_FOUND \
#   --ignore-panel=REQUESTS_STATIC \
#   --ignore-panel=VISIT_TIMES \
#   --ignore-panel=OS \
#   --ignore-panel=REQUESTS \
#   --ignore-panel=HOSTS \
#   --ignore-panel=KEYPHRASES \
#   --ignore-panel=ASN \
#   --ignore-panel=REFERRERS \
#   --ignore-panel=REFERRING_SITES \
#   --ignore-panel=BROWSERS \
#   2> >(grep -v 'Cleaning up resources...' >&2)
# $GOACCESS --restore -o ${DEST}/report_clients.html \
#   --ignore-panel=REQUESTS_STATIC \
#   --ignore-panel=NOT_FOUND \
#   --ignore-panel=VISIT_TIMES \
#   --ignore-panel=VIRTUAL_HOSTS \
#   --ignore-panel=STATUS_CODES \
#   --ignore-panel=REMOTE_USER \
#   --ignore-panel=CACHE_STATUS \
#   --ignore-panel=MIME_TYPE \
#   --ignore-panel=ASN \
#   --ignore-panel=TLS_TYPE \
#   2> >(grep -v 'Cleaning up resources...' >&2)

rm -rf $TEMP_DIR
  # --ignore-panel=VISITORS \
  # --ignore-panel=REQUESTS \
  # --ignore-panel=REQUESTS_STATIC \
  # --ignore-panel=NOT_FOUND \
  # --ignore-panel=HOSTS \
  # --ignore-panel=OS \
  # --ignore-panel=BROWSERS \
  # --ignore-panel=VISIT_TIMES \
  # --ignore-panel=VIRTUAL_HOSTS \
  # --ignore-panel=REFERRERS \
  # --ignore-panel=REFERRING_SITES \
  # --ignore-panel=KEYPHRASES \
  # --ignore-panel=STATUS_CODES \
  # --ignore-panel=REMOTE_USER \
  # --ignore-panel=CACHE_STATUS \
  # --ignore-panel=GEO_LOCATION \
  # --ignore-panel=MIME_TYPE \
  # --ignore-panel=TLS_TYPE \
  # --ignore-panel=ASN \
