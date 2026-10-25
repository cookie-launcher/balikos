#!/usr/bin/env bash
# Shared helpers for BalıkOS build/release scripts.
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/balikos-release"
# shellcheck source=/dev/null
source "${CONFIG_FILE}"
: "${VERSION:?VERSION missing from config/balikos-release}"
: "${RELEASE_NAME:?RELEASE_NAME missing from config/balikos-release}"
export VERSION RELEASE_NAME

log()  { printf '[balikos] %s\n' "$*" >&2; }
warn() { printf '[balikos] WARNING: %s\n' "$*" >&2; }
die()  { printf '[balikos] ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

need_root() {
    [[ ${EUID} -eq 0 ]] || die "this step must run as root (mkarchiso)"
}

require_arch() {
    [[ -f /etc/arch-release ]] || die "this script must run on Arch Linux (pacman/makepkg/archiso)"
}
