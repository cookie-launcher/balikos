#!/usr/bin/env bash
# Build BalıkOS packages into a local pacman repository.
#
# Run as an unprivileged Arch user.  The base kernel is built by default;
# optional scheduler variants are only built with --with-variants.
set -euo pipefail
source "$(dirname -- "$0")/lib/common.sh"
require_arch
[[ ${EUID} -ne 0 ]] || die "run as an unprivileged user (makepkg refuses root)"

WITH_VARIANTS=0
SKIP_KERNEL=0
CLEAN=0
for arg in "$@"; do
    case "$arg" in
        --with-variants) WITH_VARIANTS=1 ;;
        --skip-kernel)   SKIP_KERNEL=1 ;;
        --clean)         CLEAN=1 ;;
        -h|--help)
            printf 'usage: %s [--with-variants] [--skip-kernel] [--clean]\n' "$0"
            exit 0 ;;
        *) die "unknown argument: $arg" ;;
    esac
done

need_cmd makepkg
need_cmd repo-add
need_cmd pacman

REPO_DIR="${REPO_ROOT}/repo/x86_64"
mkdir -p "$REPO_DIR"
export PKGDEST="$REPO_DIR"
export SRCDEST="${REPO_ROOT}/cache/src"
export SRCPKGDEST="${REPO_ROOT}/cache/src"
mkdir -p "$SRCDEST" "$SRCPKGDEST"

add_repo() {
    local db="$REPO_DIR/balikos.db.tar.zst"
    local -a packages=()
    while IFS= read -r -d '' pkg; do packages+=("$pkg"); done < <(find "$REPO_DIR" -maxdepth 1 -name '*.pkg.tar.*' -print0)
    if ((${#packages[@]})); then
        repo-add --nocolor --remove "$db" "${packages[@]}" >/dev/null
    fi
}

build_one() {
    local dir="$1"
    local deps="${2:-nodeps}"
    log "building $(basename "$dir")"
    local -a args=(--noconfirm)
    [[ $CLEAN -eq 1 ]] && args+=(--cleanbuild)
    if [[ "$deps" == "syncdeps" ]]; then
        args+=(--syncdeps)
    else
        args+=(--nodeps)
    fi
    (cd "$dir" && makepkg "${args[@]}")
    add_repo
}

# Dependency order: shared branding first, then consumers.
build_one "${REPO_ROOT}/packages/balikos-branding"
build_one "${REPO_ROOT}/packages/balikos-settings"
build_one "${REPO_ROOT}/packages/balikos-hello"
build_one "${REPO_ROOT}/packages/balikos-store"
build_one "${REPO_ROOT}/packages/balikos-updater"
build_one "${REPO_ROOT}/packages/balikos-branding-gnome"
build_one "${REPO_ROOT}/packages/balikos-branding-kde"
build_one "${REPO_ROOT}/packages/balikos-wallpapers"

if [[ $SKIP_KERNEL -eq 0 ]]; then
    build_one "${REPO_ROOT}/packages/balikos-kernel" syncdeps
fi

if [[ $WITH_VARIANTS -eq 1 ]]; then
    for dir in "${REPO_ROOT}"/packages/balikos-kernel-*; do
        [[ -d "$dir" ]] || continue
        build_one "$dir" syncdeps
    done
fi

log "packages available in ${REPO_DIR}"
log "database: ${REPO_DIR}/balikos.db.tar.zst"
