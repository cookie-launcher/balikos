#!/usr/bin/env bash
# Build the BalıkOS ISO with mkarchiso using the local package repository.
set -euo pipefail
source "$(dirname -- "$0")/lib/common.sh"
require_arch
need_root
need_cmd mkarchiso
need_cmd python3

PROFILE="${REPO_ROOT}/iso"
WORK="${REPO_ROOT}/work"
OUT="${REPO_ROOT}/out"
REPO_DIR="${REPO_ROOT}/repo"
PORT="${BALIKOS_REPO_PORT:-8765}"
SERVER_PID=""

cleanup() {
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Make the repository version and the ISO's /etc/balikos-release identical.
install -Dm644 "${CONFIG_FILE}" "${PROFILE}/airootfs/etc/balikos-release"
export BALIKOS_VERSION="$VERSION"
export BALIKOS_RELEASE_NAME="$RELEASE_NAME"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"

mkdir -p "$OUT" "$WORK"
if [[ ! -f "${REPO_DIR}/x86_64/balikos.db.tar.zst" ]]; then
    die "local package repository is missing; run scripts/build-packages.sh first"
fi

# The live ISO also carries the local repository so Calamares can install
# balikos-* packages after boot without a network mirror.
install -d "${PROFILE}/airootfs/var/cache/balikos/repo/x86_64"
find "${PROFILE}/airootfs/var/cache/balikos/repo" -type f -delete
cp -a "${REPO_DIR}/x86_64/." "${PROFILE}/airootfs/var/cache/balikos/repo/x86_64/"

# archiso copies profile/airootfs before pacstrap; package-owned files would then
# conflict.  Overlay the profile after package installation so BalikOS files win.
python3 - <<'PYTHON'
from pathlib import Path
path = Path("/usr/bin/mkarchiso")
text = path.read_text()
if "_run_once _make_custom_airootfs" in text:
    text = text.replace("_run_once _make_custom_airootfs\n", "")
old = '    _msg_info "Done! Packages installed successfully."'
new = old + '\n    # Overlay BalikOS custom airootfs files after package installation\n    _unshare cp -af --no-preserve=ownership,mode -- "${profile}/airootfs/." "${pacstrap_dir}"'
if old not in text:
    raise SystemExit("mkarchiso hook point not found")
path.write_text(text.replace(old, new, 1))
PYTHON

log "serving local repository on 127.0.0.1:${PORT}"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$REPO_DIR" >/tmp/balikos-repo-http.log 2>&1 &
SERVER_PID=$!
sleep 1
kill -0 "$SERVER_PID" 2>/dev/null || die "local repository HTTP server failed"

log "building BalıkOS ${VERSION} (${RELEASE_NAME})"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

ISO="$(find "$OUT" -maxdepth 1 -name "balikos-${VERSION}-*.iso" -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -n "$ISO" && -f "$ISO" ]] || die "mkarchiso did not produce an ISO"
log "ISO: $ISO"
sha256sum "$ISO" > "${ISO}.sha256"
log "SHA256: $(cut -d' ' -f1 "${ISO}.sha256")"
"$(dirname -- "$0")/render-release-json.sh" "$ISO"
EOF
chmod +x scripts/build-iso.sh
bash -n scripts/build-iso.sh && echo build_ok