#!/bin/bash
ACC_FIREWALL_ID=_your_firewall_id_
ACC_AUTHORIZED_USERS=_your_authorized_user_
ACC_CLOUDINIT_METADATA=_your_metadata_
ACC_TLD=_your_domain_
ACC_REGION=_your_region_

# Create the Linode and capture its ID
# We use the xkcdpass utility to generate a random label
# We use openssl to generate a random password
# We use curl to fetch the cloud-init metadata
# We use a custom image that has the latest version of Ubuntu 22.04 LTS
ACC_CREATE_OUTPUT=$(linode-cli linodes create \
  --authorized_users $ACC_AUTHORIZED_USERS \
  --backups_enabled false \
  --booted true \
  --image 'private/22740906' \
  --label "$(xkcdpass -d - -n 2 -C lower)" \
  --private_ip false \
  --firewall_id $ACC_FIREWALL_ID \
  --region "$ACC_REGION" \
  --root_pass "$(openssl rand -base64 32 | tr -d /=+ | cut -c -32)" \
  --tags "tld: $ACC_TLD" \
  --tags 'quick-build' \
  --type g7-premium-4 \
  --metadata.user_data="$(curl -s $ACC_CLOUDINIT_METADATA | base64)" \
  --json | grep '^\[')

# Verify we have valid JSON before continuing
if ! jq -e . >/dev/null 2>&1 <<<"$ACC_CREATE_OUTPUT"; then
    echo "Failed to parse JSON output from Linode create command."
    exit 1
fi

ACC_LINODE_ID=$(echo "$ACC_CREATE_OUTPUT" | jq -r '.[0].id')
ACC_LABEL=$(echo "$ACC_CREATE_OUTPUT" | jq -r '.[0].label')

# Wait for the Linode to be provisioned and grab the IP address
# This is a simple loop that checks every 10 seconds to see if the IP is available
# It will timeout after 10 tries (100 seconds)
TRIES=10
while [ $TRIES -gt 0 ]; do
    ACC_IP=$(linode-cli linodes view $ACC_LINODE_ID --json | jq -r '.[0].ipv4[0]')
    if [ -n "$ACC_IP" ]; then
        break
    fi
    sleep 10
    TRIES=$((TRIES-1))
done

# Check if we got an IP address
if [ -z "$ACC_IP" ]; then
    echo "Failed to get an IP address for the Linode."
    exit 1
fi

# Look up the domain ID based on the TLD tag
DOMAIN_ID=$(linode-cli domains list --json | jq -r --arg TLD "$ACC_TLD" '.[] | select(.domain == $TLD) | .id')

# Check if we got a domain ID
if [ -z "$DOMAIN_ID" ]; then
    echo "Failed to find the domain ID for $ACC_TLD."
    exit 1
fi

# Create the DNS A record
RECORD_NAME="$ACC_LABEL.$ACC_REGION"
RECORD_CREATE="$(linode-cli domains records-create $DOMAIN_ID \
  --type A \
  --name $RECORD_NAME \
  --target $ACC_IP \
  --ttl_sec 300)"

# Print the IP address
echo "FQDN: $RECORD_NAME.$ACC_TLD -(A)-> $ACC_IP"