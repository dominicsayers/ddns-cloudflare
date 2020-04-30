#!/bin/bash
# Original: https://github.com/netphantm/scripts (MIT License)
# Author: Hugo <mail@hugo.ro>
# Meddled with by: Dominic Sayers <dominic@sayers.cc>
#
# Dynamically update DNS on cloudflare through their API.
# Uses jq (dirty, I know!).
# Set CONFIG values to your needs.

# See the cloudflare API documentation about how to get the values for your account: https://api.cloudflare.com/#zone-list-zones
# Make a file called ~/.ddns/cloudflare with the correct values for your DNS in this format:
API_ID="your_cloudflare_login@example.com"
API_AUTH_KEY="1234567890foo1234567890" # Get this from the API tokens tab in your account page
ZONE_NAME="your.domain.com"
ZONE_ID="123456789012345678901234567890" # Get this from your domain's overview page
DNSREC_ID="123456789012345678901234567890" # Get this by running this script with --list

set -a
. ~/.ddns/cloudflare
set +a

# No need to change anything beyond this point

if [[ "$API_AUTH_KEY" == *"foo"* ]]; then
  echo "ERROR - Please edit the script and set the config variables first!"
  exit 1
fi

# show usage
usage() {
  printf "\nUsage:\n"
  printf "$(basename $0) [-f|--force]\n"
  printf "      -f | --force - Force DNS update\n"
  printf "      -d | --debug - Enable debug\n"
}

API_URL="https://api.cloudflare.com/client/v4/zones"

# get command line switches
while [ -n "$1" ]; do
    case "$1" in
        -f | --force)
            FORCE=true
            ;;
        -d | --debug)
            DEBUG=true
            ;;
        -l | --list)
            curl -s -X GET "$API_URL/$ZONE_ID/dns_records" \
              -H "X-Auth-Email: $API_ID" \
              -H "X-Auth-Key: $API_AUTH_KEY" \
              -H "Content-Type: application/json"
            exit 1
            ;;
        *)
            printf "Unknown argument: $1\n"
            usage
            exit 1
            ;;
    esac
    shift
done

# get IP from cloudflare
DNS_IP=`curl -s -X GET "$API_URL/$ZONE_ID/dns_records/$DNSREC_ID" \
     -H "X-Auth-Email: $API_ID" \
     -H "X-Auth-Key: $API_AUTH_KEY" \
     -H "Content-Type: application/json" | jq . | grep content | awk -F\" '{print $4}'`

if [ ! $DNS_IP ]; then
  echo "ERROR - Getting DNS entry from cloudflare didn't work!"
  echo "Check your credentials."
  exit 1
fi

# get current external IP
CURRENT_IP=`curl -s http://icanhazip.com`

if [ "$DNS_IP" != "$CURRENT_IP" ] || [ $FORCE ]; then
  UPDATE=`curl -s -X PUT "$API_URL/$ZONE_ID/dns_records/$DNSREC_ID" \
       -H "X-Auth-Email: $API_ID" \
       -H "X-Auth-Key: $API_AUTH_KEY" \
       -H "Content-Type: application/json" \
       --data '{"type":"A","name":"'"$ZONE_NAME"'","content":"'"$CURRENT_IP"'","ttl":1,"proxied":false}'  | jq .`
  SUCCESS=`echo "$UPDATE" | jq .'success'`
  DBG="INFO - renewed IP with: '$CURRENT_IP', success=$SUCCESS"
  logger --tag cloudflare-update $DBG
else
  DBG="INFO - IP unchanged: '$CURRENT_IP'"
  logger --tag cloudflare-update $DBG
fi

if [ $DEBUG ]; then
  echo "CURRENT_IP=$CURRENT_IP"
  echo "DNS_IP=$DNS_IP"
  if [ $SUCCESS ]; then
    echo $UPDATE | jq .
  fi
  echo "$DBG"
fi
