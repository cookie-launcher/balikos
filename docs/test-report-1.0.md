# BalıkOS 1.0 remaster — test report

Date: 2026-10-25

Artifact: `/home/emre/balikos-build/out/balikos-1.0-x86_64.iso`
SHA256: `539b491af5b08e3e5931686939d883c53c3907e12b0b6f26762445831490b3b6`

## Passed

| Check | Evidence |
|---|---|
| BIOS live boot, BalıkOS menu + Plymouth + GDM autologin | QEMU / `BalikOS-1.0-BIOS` libvirt domain, screenshots `libvirt-bios3.png` |
| UEFI live boot (OVMF, systemd-boot menu) | QEMU / `BalikOS-1.0-UEFI`, screenshot `libvirt-uefi.png` |
| Calamares welcome, location map blue, keyboard preview blue, bootloader options, GNOME + GNOME Dark, partitions, users, summary | screenshots `new-loc2.png`, `new-kbd.png`, `inst-boot.png`, `inst-desktop.png`, `new-summary.png` |
| Full install to 30 GB btrfs disk (BIOS/GRUB) | installed VM disk `BalikOS-1.0-test.qcow2`; Calamares "Her şey tamam" |
| Installed system boots, GDM, login, GNOME desktop | serial log + `installed-desktop2.png` |
| Default wallpaper / dark accent / blue links | `installed-desktop2.png` |
| First-login BalıkOS Hello | `installed-desktop2.png` |
| BalıkOS Store search (36 gimp results) | `installed-store-search.png` |
| BalıkOS Wallpapers: 2-column grid, apply Derinlik | `installed-wallpapers.png`, `wall-applied.png` |
| `/etc/os-release`, hostname `balikos`, updater timer started | installed terminal / serial log |

## Known limitations

- The remaster keeps the CachyOS kernel package (`linux-cachyos`); `uname -r` ends in `-cachyos`.  The source tree's `balikos-kernel` is the next-build fix.
- Firmware is copied from the live image, not installed as split `linux-firmware` packages.
- GDM uses a dark fallback background; the desktop and lock screen use the BalıkOS wallpaper.
- The GDM logo is a 96 px mark; the 512 px source version made the login layout unusable and was replaced in the final ISO.
