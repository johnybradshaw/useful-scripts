# useful-scripts

Scripts that are useful for doing things

## Ubuntu

| File/Folder Name | Explanation |
| --- | --- |
| acc-set-hostname.sh | Sets the hostname of the ACC linode as the label and tag |
| auto-logout.sh | Sets a 10 minute timeout on the *physical* console (tty) |
| install_rstudio.sh | Installs R-Studio and required dependencies |

## macOS

| File/Folder Name | Explanation |
| --- | --- |
| alias-linode-cli.sh | Aliases useful `linode-cli` commands |
| linode-prune.sh | Deletes all linodes with the *quick-build* tag |
| linode-quick.sh | Quickly builds a linode |

```bash
alias linode-prune='linode-cli linodes list --json | jq -r ".[] | select(.tags | index(\"quick-build\")) | .id" | xargs -I {} linode-cli linodes delete {}'
alias linode-prune-dry-run='linode-cli linodes list --json | jq -r ".[] | select(.tags | index(\"quick-build\")) | .id" | xargs -I {} linode-cli linodes delete {} --dry-run'
alias linode-quick='~/GitHub/useful-scripts/macos/cli/linode-quick.sh'
alias linode-prune-volumes="linode-cli volumes list --json | jq -r '.[] | select(.linode_id == null) | .id' | xargs -I {} linode-cli volumes delete {}" # Deletes all unattached Volumes
```
