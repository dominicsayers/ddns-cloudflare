# Dynamic DNS updater for Cloudflare

Dynamically update DNS on Cloudflare through their API.

## How to use this script

See the [Cloudflare API documentation](https://api.cloudflare.com/#zone-list-zones) for information about how to get the values for your account

Make a file called `~/.ddns/cloudflare` with the correct values for your DNS in this format:

```bash
API_ID="your_cloudflare_login@example.com"
API_AUTH_KEY="1234567890foo1234567890" # Get this from the API tokens tab in your account page
ZONE_NAME="your.domain.com"
ZONE_ID="123456789012345678901234567890" # Get this from your domain's overview page
DNSREC_ID="123456789012345678901234567890" # Get this by running this script with --list
```

The `DNSREC_ID` is the API's `id` of the record you want to update. You can find it if you look at all the records in your DNS zone through the API. One way of doing that is to run this script with the `--list` parameter:

```bash
ddns-cloudflare.sh --list
```

## Prerequisites

This script assumes `jq` is installed. Installation instructions for `jq` are beyond the scope of this README but, for example, on Ubuntu you'd type:

```bash
sudo snap install jq
```

## Acknowledgements

Most of this script is cribbed from `netphantm`'s [miscellaneous scripts](https://github.com/netphantm/scripts) repository.
