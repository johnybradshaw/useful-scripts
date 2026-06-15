#!/usr/bin/env bash
################################################################################
# protect-default-branch.sh
#
# Apply classic branch protection to the DEFAULT branch of every repo owned by
# a GitHub user/org, requiring a pull request before merging and blocking
# direct pushes.
#
# Requires: gh (authenticated, scope: repo), jq
#
# Examples:
#   ./protect-default-branch.sh                 # protect your own non-fork repos
#   ./protect-default-branch.sh --dry-run       # show what would change
#   ./protect-default-branch.sh --owner acme --approvals 1 --enforce-admins
#   ./protect-default-branch.sh --include-forks --include-archived
#
# Defaults are tuned for solo personal repos: 0 required approvals (so you can
# merge your own PRs) and admin bypass left ON (enforce_admins=false).
################################################################################
set -euo pipefail

OWNER=""
APPROVALS=0
ENFORCE_ADMINS=false
INCLUDE_FORKS=false
INCLUDE_ARCHIVED=false
DRY_RUN=false

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --owner)            OWNER="${2:?--owner needs a value}"; shift 2 ;;
    --approvals)        APPROVALS="${2:?--approvals needs a value}"; shift 2 ;;
    --enforce-admins)   ENFORCE_ADMINS=true; shift ;;
    --include-forks)    INCLUDE_FORKS=true; shift ;;
    --include-archived) INCLUDE_ARCHIVED=true; shift ;;
    --dry-run)          DRY_RUN=true; shift ;;
    -h|--help)          usage 0 ;;
    *) echo "Unknown argument: $1" >&2; usage 1 ;;
  esac
done

command -v gh >/dev/null 2>&1 || { echo "error: gh not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "error: jq not found" >&2; exit 1; }

# Default to the authenticated user when no owner is given.
if [ -z "$OWNER" ]; then
  OWNER="$(gh api user --jq '.login')"
fi

# Build the repo list. --source already excludes forks; we add an explicit
# filter so --include-forks is honoured, plus archived and empty-repo handling.
list_args=(--limit 1000 --json name,defaultBranchRef,isFork,isArchived)
[ "$INCLUDE_ARCHIVED" = true ] || list_args+=(--no-archived)

filter='.[]'
[ "$INCLUDE_FORKS" = true ]    || filter="$filter | select(.isFork==false)"
[ "$INCLUDE_ARCHIVED" = true ] && filter="$filter | select(.isArchived==true or .isArchived==false)"
filter="$filter | select(.defaultBranchRef.name != null) | \"\(.name)\t\(.defaultBranchRef.name)\""

repos="$(gh repo list "$OWNER" "${list_args[@]}" --jq "$filter")"

if [ -z "$repos" ]; then
  echo "No matching repos for owner '$OWNER'." >&2
  exit 0
fi

# enforce_admins must be a JSON boolean, not a string.
payload="$(jq -n \
  --argjson approvals "$APPROVALS" \
  --argjson enforce "$ENFORCE_ADMINS" \
  '{
     required_status_checks: null,
     enforce_admins: $enforce,
     required_pull_request_reviews: { required_approving_review_count: $approvals },
     restrictions: null
   }')"

echo "Owner=$OWNER  approvals=$APPROVALS  enforce_admins=$ENFORCE_ADMINS" \
     "include_forks=$INCLUDE_FORKS  include_archived=$INCLUDE_ARCHIVED  dry_run=$DRY_RUN"
echo

ok=0; fail=0
while IFS="$(printf '\t')" read -r repo branch; do
  [ -z "$repo" ] && continue
  if [ "$DRY_RUN" = true ]; then
    printf 'DRY  %s (%s)\n' "$repo" "$branch"
    continue
  fi
  if printf '%s' "$payload" | gh api -X PUT \
       "repos/${OWNER}/${repo}/branches/${branch}/protection" \
       -H "Accept: application/vnd.github+json" --input - >/dev/null 2>/tmp/_protect_err; then
    ok=$((ok + 1)); printf 'OK   %s (%s)\n' "$repo" "$branch"
  else
    fail=$((fail + 1))
    printf 'FAIL %s (%s): %s\n' "$repo" "$branch" "$(tr -d '\n' < /tmp/_protect_err)"
  fi
done <<EOF
$repos
EOF

echo
echo "----- ok=$ok fail=$fail -----"
