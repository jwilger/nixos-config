#!/usr/bin/env bash
# Bulk-migrate GitHub repositories into Forgejo.
#
# Required env:
#   GITHUB_TOKEN    PAT with repo + read:org access to every github_owner
#                   you list in MIGRATE_PAIRS.
#   GITHUB_USER     Your GitHub login (used to detect "user repos" vs
#                   "org repos" listing endpoints).
#   FORGEJO_URL     e.g. https://git.johnwilger.com
#   FORGEJO_TOKEN   Forgejo admin PAT (Settings -> Applications -> Generate New Token).
#
# Optional env:
#   MIGRATE_PAIRS   Space-separated github_owner:forgejo_owner pairs.
#                   Default: "jwilger:jwilger slipstream-consulting:slipstream-consulting"
#
# Idempotent: 409 (already exists) is logged and skipped, not a failure.

set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${GITHUB_USER:?GITHUB_USER is required}"
: "${FORGEJO_URL:?FORGEJO_URL is required}"
: "${FORGEJO_TOKEN:?FORGEJO_TOKEN is required}"

MIGRATE_PAIRS="${MIGRATE_PAIRS:-jwilger:jwilger slipstream-consulting:slipstream-consulting}"

GH_API="https://api.github.com"
FORGEJO_URL="${FORGEJO_URL%/}"

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 not found in PATH" >&2; exit 1; }
}
require curl
require jq

log() { printf '[%s] %s\n' "${PAIR_TAG:-init}" "$*"; }

ensure_forgejo_org() {
  local owner="$1"
  if [ "$owner" = "$GITHUB_USER" ]; then
    return 0
  fi

  local code
  code=$(curl -sS -o /tmp/forgejo-org-create.json -w '%{http_code}' \
    -X POST \
    -H "Authorization: token $FORGEJO_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"$owner\",\"visibility\":\"private\"}" \
    "$FORGEJO_URL/api/v1/orgs")

  case "$code" in
    201)         log "Created Forgejo org: $owner" ;;
    409|422)     log "Forgejo org already exists: $owner" ;;
    *)
      log "ERROR: failed to create Forgejo org $owner (HTTP $code)"
      cat /tmp/forgejo-org-create.json >&2 || true
      return 1
      ;;
  esac
}

list_github_repos() {
  local owner="$1"
  local page=1
  local endpoint
  if [ "$owner" = "$GITHUB_USER" ]; then
    endpoint="$GH_API/user/repos?affiliation=owner&per_page=100"
  else
    endpoint="$GH_API/orgs/$owner/repos?per_page=100&type=all"
  fi

  while :; do
    local body
    body=$(curl -sS \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H 'Accept: application/vnd.github+json' \
      "${endpoint}&page=${page}")

    local count
    count=$(echo "$body" | jq 'length')
    if [ "$count" -eq 0 ]; then
      break
    fi

    if [ "$owner" = "$GITHUB_USER" ]; then
      echo "$body" | jq -c \
        --arg owner "$owner" \
        '.[] | select(.owner.login == $owner) | {name: .name, clone_url: .clone_url, private: .private, archived: .archived}'
    else
      echo "$body" | jq -c \
        '.[] | {name: .name, clone_url: .clone_url, private: .private, archived: .archived}'
    fi

    if [ "$count" -lt 100 ]; then
      break
    fi
    page=$((page + 1))
  done
}

migrate_repo() {
  local forgejo_owner="$1"
  local repo_json="$2"

  local name clone_url private archived
  name=$(echo "$repo_json" | jq -r '.name')
  clone_url=$(echo "$repo_json" | jq -r '.clone_url')
  private=$(echo "$repo_json" | jq -r '.private')
  archived=$(echo "$repo_json" | jq -r '.archived')

  local payload
  payload=$(jq -n \
    --arg service       "github" \
    --arg clone_addr    "$clone_url" \
    --arg auth_token    "$GITHUB_TOKEN" \
    --arg repo_owner    "$forgejo_owner" \
    --arg repo_name     "$name" \
    --argjson private   "$private" \
    '{
      service:       $service,
      clone_addr:    $clone_addr,
      auth_token:    $auth_token,
      repo_owner:    $repo_owner,
      repo_name:     $repo_name,
      mirror:        false,
      private:       $private,
      issues:        true,
      pull_requests: true,
      releases:      true,
      wiki:          true,
      labels:        true,
      milestones:    true
    }')

  local code
  code=$(curl -sS -o /tmp/forgejo-migrate.json -w '%{http_code}' \
    -X POST \
    -H "Authorization: token $FORGEJO_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "$FORGEJO_URL/api/v1/repos/migrate")

  local archived_tag=""
  [ "$archived" = "true" ] && archived_tag=" [archived]"

  case "$code" in
    201)
      log "  migrated: $forgejo_owner/$name${archived_tag}"
      ;;
    409)
      log "  exists:   $forgejo_owner/$name${archived_tag}"
      ;;
    *)
      log "  FAILED:   $forgejo_owner/$name${archived_tag} (HTTP $code)"
      cat /tmp/forgejo-migrate.json >&2 || true
      ;;
  esac
}

for pair in $MIGRATE_PAIRS; do
  github_owner="${pair%%:*}"
  forgejo_owner="${pair##*:}"
  PAIR_TAG="$github_owner -> $forgejo_owner"

  log "Starting migration"
  ensure_forgejo_org "$forgejo_owner"

  list_github_repos "$github_owner" | while read -r repo_json; do
    [ -z "$repo_json" ] && continue
    migrate_repo "$forgejo_owner" "$repo_json"
  done

  log "Done"
done
