#!/usr/bin/env bash
# Generate the release feed JSON consumed by balikos-updater.
set -euo pipefail
source "$(dirname -- "$0")/lib/common.sh"
cd "$REPO_ROOT"
[[ $# -ge 1 ]] || die "usage: $0 <iso>"
ISO="$1"
[[ -f "$ISO" ]] || die "ISO not found: $ISO"
need_cmd sha256sum

SF_PROJECT="${SF_PROJECT:-balikos}"
SF_DIR="${SF_DIR:-releases}"
ISO_NAME="$(basename "$ISO")"
SHA256="$(sha256sum "$ISO" | cut -d' ' -f1)"
SIZE="$(stat -c '%s' "$ISO")"
ISO_URL="${BALIKOS_ISO_URL:-https://sourceforge.net/projects/${SF_PROJECT}/files/${SF_DIR}/${ISO_NAME}/download}"
NOTES_URL="${BALIKOS_NOTES_URL:-https://balikos.org/releases/${VERSION}}"
PUBLISHED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
export VERSION RELEASE_NAME ISO_NAME SHA256 SIZE ISO_URL NOTES_URL PUBLISHED
mkdir -p "${REPO_ROOT}/out"
python3 - <<'PY'
import json, os
payload = {
    "version": os.environ["VERSION"],
    "release_name": os.environ["RELEASE_NAME"],
    "release_notes_url": os.environ["NOTES_URL"],
    "iso_url": os.environ["ISO_URL"],
    "iso_name": os.environ["ISO_NAME"],
    "sha256": os.environ["SHA256"],
    "size": int(os.environ["SIZE"]),
    "published": os.environ["PUBLISHED"],
}
with open("out/release.json", "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
log "wrote out/release.json"
