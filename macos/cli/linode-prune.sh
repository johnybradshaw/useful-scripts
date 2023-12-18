#!/bin/bash

# Fetch all Linodes with the "quick-build" tag and their IPv4 addresses
linodes_to_prune=$(linode-cli linodes list --json | jq -rc '.[] | select(.tags[] | contains("quick-build")) | {id, ips: .ipv4}')

# Loop through each Linode
echo "$linodes_to_prune" | while IFS= read -r linode; do
  linode_id=$(echo "$linode" | jq -r ".id")
  linode_ips=$(echo "$linode" | jq -r ".ips[]")

  # Loop through each IP of the current Linode
  for ip in $linode_ips; do
    # Fetch all domains
    domain_ids=$(linode-cli domains list --json | jq -r '.[].id')

    for domain_id in $domain_ids; do
      # Fetch the domain records for each domain and filter for the ones matching the Linode's IP
      domain_records=$(linode-cli domains records-list $domain_id --json)
      record_ids=$(echo "$domain_records" | jq -r --arg ip "$ip" '.[] | select(.target == $ip) | .id')

      # Delete the DNS records with matching IP
      for record_id in $record_ids; do
        if [ -n "$record_id" ] && [ "$record_id" != "null" ]; then
          linode-cli domains records-delete $domain_id $record_id
        fi
      done
    done
  done

  # Now delete the Linode
  linode-cli linodes delete $linode_id
done

echo "All 'quick-build' Linodes and their associated DNS records have been deleted."
