#!/bin/bash
ACC_FIREWALL_ID=_your_firewall_id_
ACC_AUTHORIZED_USERS=_your_authorized_user_
ACC_CLOUDINIT_METADATA=_your_metadata_
ACC_TLD=_your_domain_
ACC_REGION=_your_region_

alias linode-prune='linode-cli linodes list --json | jq -r ".[] | select(.tags | index(\"quick-build\")) | .id" | xargs -I {} linode-cli linodes delete {}'
alias linode-prune-dry-run='linode-cli linodes list --json | jq -r ".[] | select(.tags | index(\"quick-build\")) | .id" | xargs -I {} linode-cli linodes delete {} --dry-run'
alias linode-quick='~/GitHub/useful-scripts/macos/cli/linode-quick.sh'
alias linode-prune-volumes="linode-cli volumes list --json | jq -r '.[] | select(.linode_id == null) | .id' | xargs -I {} linode-cli volumes delete {}"
