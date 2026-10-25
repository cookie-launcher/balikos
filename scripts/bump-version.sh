#!/usr/bin/env bash
# Bump the single BalıkOS version source.  Build, package and feed scripts
# consume config/balikos-release; never edit their version literals.
set -euo pipefail
source "$(dirname -- "$0")/lib/common.sh"
[[ $# -ge 1 ]] || die "usage: $0 <version> [release name]"
new="$1"
name="${2:-BalıkOS $new}"
[[ "$new" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || die "invalid version: $new"
printf 'VERSION=%s\nRELEASE_NAME="%s"\n' "$new" "$name" > "$CONFIG_FILE"
log "version -> $new ($name)"
log "next: rebuild packages/ISO, run scripts/render-release-json.sh, then scripts/publish-release.sh"
