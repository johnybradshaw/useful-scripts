#!/bin/bash
################################################################################################
# Usage #
################################################################################################
# Ensure a tag is created in the form: "tld: yourdomain.com" and applied to the Linode
# Add this to /usr/bin/local/acc-set-hostname.sh
# Call this file during the cloud-init <runcmd> block
################################################################################################
METADATA_TOKEN="$(curl -s -X PUT -H 'Metadata-Token-Expiry-Seconds: 3600' 'http://169.254.169.254/v1/token')"
METADATA_URL="http://169.254.169.254/v1/instance"
METADATA=$(curl -s -H "Metadata-Token: $METADATA_TOKEN" "$METADATA_URL")
LABEL=$(echo "$METADATA" | awk '/^label:/ {print $2}')
TLD=$(echo "$METADATA" | awk '/^tags: tld:/ {print $3}')
hostnamectl hostname "$LABEL.$TLD"