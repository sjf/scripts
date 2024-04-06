#!/bin/bash
set -eu

DOMAIN="oak.sjf.io"

# Get external IP address
EXT_IP=$(curl -s ifconfig.me)  

#Get the current Zone for the provided domain
#CURRENT_ZONE_HREF=$(curl -s -H "Authorization: Bearer $PAT" https://dns.api.gandi.net/api/v5/domains/$DOMAIN | jq -r '.zone_records_href')
HOSTED_ZONE_ID=Z2FDFOEC7I1LFT
LOG_FILE=~/log/update_dns.log

# # Update the A Record of the subdomain using PUT
# curl -D- -X PUT -H "Content-Type: application/json" \
#         -H "Authorization: Bearer $PAT" \
#         -d "{\"rrset_name\": \"$SUBDOMAIN\",
#              \"rrset_type\": \"A\",
#              \"rrset_ttl\": 1200,
#              \"rrset_values\": [\"$EXT_IP\"]}" \
#         $CURRENT_ZONE_HREF/$SUBDOMAIN/A

#         #         -H "X-Api-Key: $API_KEY" \

UPDATE="{ \"Changes\": [ {
     \"Action\": \"UPSERT\",
     \"ResourceRecordSet\": {
     \"Name\": \"$DOMAIN\",
     \"Type\": \"A\",
     \"TTL\": 300,
     \"ResourceRecords\": [ {
     \"Value\": \"$EXT_IP\" } ] } } ] }"

echo $(date) Updating IP | tee -a $LOG_FILE
echo $UPDATE | tee -a $LOG_FILE
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch "$UPDATE" | tee -a $LOG_FILE
echo | tee -a $LOG_FILE
