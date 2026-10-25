#!/usr/bin/env bash
# Headless smoke test for the live ISO on BIOS and UEFI.
# The live kernel is built with console=ttyS0 so boot progress is observable.
set -euo pipefail
source "$(dirname -- "$0")/lib/common.sh"

MODE="bios"
ISO=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bios) MODE="bios"; shift ;;
        --uefi) MODE="uefi"; shift ;;
        --iso) ISO="$2"; shift 2 ;;
        -h|--help) printf 'usage: %s [--bios|--uefi] [--iso PATH]\n' "$0"; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done
need_cmd qemu-system-x86_64
[[ -n "$ISO" ]] || ISO="$(find "${REPO_ROOT}/out" -maxdepth 1 -name "balikos-${VERSION}-*.iso" -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -n "$ISO" && -f "$ISO" ]] || die "ISO not found"
LOG="$(mktemp /tmp/balikos-qemu-${MODE}-XXXX.log)"
QEMU_ARGS=(-machine pc -m 4096 -smp 2 -cdrom "$ISO" -boot d -display none -serial "file:${LOG}" -monitor none -no-reboot)

if [[ "$MODE" == "uefi" ]]; then
    OVMF=""
    for candidate in /usr/share/edk2/x64/OVMF_CODE.fd /usr/share/edk2-ovmf/x64/OVMF_CODE.fd /usr/share/ovmf/x64/OVMF_CODE.fd; do
        [[ -f "$candidate" ]] && OVMF="$candidate" && break
    done
    [[ -n "$OVMF" ]] || die "OVMF firmware not found (install edk2-ovmf)"
    QEMU_ARGS+=(-bios "$OVMF")
fi

log "booting ${ISO##*/} (${MODE}); serial: ${LOG}"
timeout 180 qemu-system-x86_64 "${QEMU_ARGS[@]}" >/tmp/balikos-qemu.out 2>&1 || true

if ! grep -q 'Linux version' "$LOG"; then
    cat "$LOG" | tail -40 >&2 || true
    die "kernel did not reach serial console (${MODE})"
fi
if ! grep -qiE 'balikos|Reached target graphical.target|gdm|gnome-shell' "$LOG"; then
    warn "kernel booted but graphical/Calamares evidence not found in serial log (${MODE})"
fi
log "boot smoke test passed (${MODE})"
