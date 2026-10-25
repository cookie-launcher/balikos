#!/usr/bin/env bash
# Publish an ISO + release.json to SourceForge.
#
# Required environment for upload:
#   SF_USER      SourceForge username
#   SF_PROJECT   SourceForge project (default: balikos)
#   SF_DIR       release directory (default: releases)
# Optional:
#   BALIKOS_ISO_URL / BALIKOS_NOTES_URL
set -euo pipefail
source "$(dirname -- "$0")/lib/common.sh"

ISO=""
NO_GIT=0
NO_UPLOAD=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --iso) ISO="$2"; shift 2 ;;
        --no-git) NO_GIT=1; shift ;;
        --no-upload) NO_UPLOAD=1; shift ;;
        -h|--help) printf 'usage: %s [--iso PATH] [--no-git] [--no-upload]\n' "$0"; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done
[[ -n "$ISO" ]] || ISO="$(find "${REPO_ROOT}/out" -maxdepth 1 -name "balikos-${VERSION}-*.iso" -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -n "$ISO" && -f "$ISO" ]] || die "ISO not found; pass --iso"

"$(dirname -- "$0")/render-release-json.sh" "$ISO"

if [[ $NO_GIT -eq 0 ]] && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/v${VERSION}" >/dev/null; then
        git -C "$REPO_ROOT" tag -a "v${VERSION}" -m "BalıkOS ${VERSION}"
    fi
    git -C "$REPO_ROOT" push origin "v${VERSION}" || warn "git push failed; tag exists locally"
fi

if [[ $NO_UPLOAD -eq 1 ]]; then
    log "upload skipped; artifacts are in ${REPO_ROOT}/out"
    exit 0
fi
: "${SF_USER:?set SF_USER for SourceForge upload}"
SF_PROJECT="${SF_PROJECT:-balikos}"
SF_DIR="${SF_DIR:-releases}"
need_cmd scp
need_cmd rsync
scp "$ISO" "${ISO}.sha256" "${REPO_ROOT}/out/release.json" \
    "${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${SF_DIR}/"
if [[ -d "${REPO_ROOT}/repo/x86_64" ]]; then
    rsync -a --delete "${REPO_ROOT}/repo/x86_64/" \
        "${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/x86_64/"
fi
log "published ${RELEASE_NAME}"
log "feed: https://sourceforge.net/projects/${SF_PROJECT}/files/${SF_DIR}/release.json/download"
