# BalıkOS source tree

BalıkOS is a CachyOS/Arch-based rolling-release live and installable
distribution.

## Current remaster artifact

`/home/emre/balikos-build/out/balikos-1.0-x86_64.iso`
Download: https://gofile.io/d/7BeBRq9f

SHA256 `539b491af5b08e3e5931686939d883c53c3907e12b0b6f26762445831490b3b6`.
This ISO was tested in QEMU/libvirt on BIOS and UEFI and installed to
a 30 GB btrfs disk.  The profiles `BalikOS-1.0-BIOS` and
`BalikOS-1.0-UEFI` are defined in `qemu:///system`.  This repository is the source of truth for the ISO profile,
Calamares configuration, BalıkOS packages, branding and the release/update
pipeline.

The previous ISO was a build artifact (a squashfs/Calamares remaster); this
tree is a clean source reconstruction.  Existing installed systems are
upgraded in place; they are not reinstalled.

## Remastered 1.0 ISO

The tested `balikos-1.0-x86_64.iso` was produced by remastering the
prior live image (this host has no pacman/makepkg/mkarchiso).  It carries
the Calamares installer fixes, the BalıkOS wallpaper set, blue accents,
GDM/desktop defaults, the Hello/Store/Wallpapers apps and BIOS+UEFI boot.
The source tree below is the clean-room build path for the next release.

## Layout

```text
config/balikos-release        single source of truth for VERSION / RELEASE_NAME
iso/                          archiso profile (mkarchiso)
  profiledef.sh
  packages.x86_64             pinned live package list
  pacman.conf                 Arch + CachyOS + local [balikos] repository
  airootfs/                   live configuration, Calamares, branding
  syslinux/, grub/, efiboot/  boot menus (balikos-kernel paths)
packages/
  balikos-kernel/             fork of CachyOS linux-cachyos + preset/install hook
  balikos-kernel-*/           scheduler variants (bore, lts, bmq, eevdf, ...)
  balikos-branding/           shared Plymouth, GRUB, SDDM, wallpapers, sound
  balikos-branding-gnome/     GDM/GNOME dconf branding
  balikos-branding-kde/       SDDM/KDE Plasma branding
  balikos-settings/           defaults and /etc/skel
  balikos-hello/              GTK welcome app
  balikos-wallpapers/         wallpaper picker app
  balikos-store/              GTK package browser + Bazaar integration
  balikos-updater/            release/package updater, timer, post-update hook
scripts/
  build-packages.sh           makepkg + repo-add local [balikos] repository
  build-iso.sh / mkiso        mkarchiso wrapper
  bump-version.sh             update the single version source
  publish-release.sh          tag, release.json, SourceForge upload
  render-release-json.sh      feed generation
  test-iso-qemu.sh            headless BIOS/UEFI smoke test
.github/workflows/build.yml   ISO + package CI and tagged release upload
```

## Calamares bootloaders

`iso/airootfs/etc/calamares/modules/packagechooser_bootloader.conf` offers:

- GRUB on BIOS and UEFI
- systemd-boot on UEFI (`efiOnly`)
- rEFInd and rEFInd + AI SDK on UEFI (`efiOnly`)
- Limine on BIOS/UEFI (CachyOS upstream option)

The Calamares desktop step is after Keyboard and before Partition.  GNOME and
GNOME (Dark) are available; KDE Plasma is available from the same package
chooser/netinstall groups.  Unsupported combinations are hidden by Calamares'
`efiOnly` handling rather than being shown and failing later.

## Kernel fork

`packages/balikos-kernel` is a fork of CachyOS `linux-cachyos`:

- same source tarball, `config`, patches, scheduler and build options,
- package/base name `balikos-kernel`,
- `provides=(linux-cachyos linux)`, `conflicts=(linux-cachyos linux)`,
- split `balikos-kernel-headers` with matching provides/conflicts,
- localversion suffix `balikos`, therefore `uname -r` reports `*-balikos`,
- a mkinitcpio preset and install hook expose `/boot/vmlinuz-balikos-kernel`
  and `/boot/initramfs-balikos-kernel.img`.

Variants (`balikos-kernel-bore`, `-lts`, `-bmq`, `-eevdf`, `-hardened`,
`-server`, `-rt-bore`, `-deckify`, `-rc`) are generated from the corresponding
upstream CachyOS PKGBUILDs with the same rename-only rule.  A kernel bump is
only `pkgver`/`_tagrel` plus rebuild; do not edit config or patches during a
bump.

## Release and update flow

`config/balikos-release` is the only version source.  Build and package
scripts read it; `iso/airootfs/etc/balikos-release` is synchronized by
`build-iso.sh`.

- `balikos-updater` runs daily via `balikos-updater.timer` (randomized delay)
  and on demand.
- Release feed: GitHub Releases `release.json` (JSON) with `version`,
  `release_name`, `release_notes_url`, `iso_url`, `sha256`.
- A newer milestone produces a desktop notification with **Update** and
  **Snooze** actions.  Package-only updates use the normal notifier.
- Applying runs `pacman -Syu` and all executable hooks in
  `/usr/lib/balikos/update-hooks/`; `50-balikos-release` writes the new
  `/etc/balikos-release` idempotently.
- Offline, malformed feed, SourceForge failure and downgrade attempts are
  logged and ignored.  The updater is disabled with `balikos-updater
  --disable` or `enabled = false` in `/etc/balikos/updater.conf`.

Publishing `1.1`:

```bash
./scripts/bump-version.sh 1.1
./scripts/build-packages.sh
sudo ./scripts/build-iso.sh
./scripts/test-iso-qemu.sh --bios
./scripts/test-iso-qemu.sh --uefi
SF_USER=youruser SF_PROJECT=balikos ./scripts/publish-release.sh
```

`publish-release.sh` creates tag `v1.1`, writes `out/release.json`, and uploads
the ISO, checksum and feed to
`frs.sourceforge.net:/home/frs/project/<project>/releases/`.

## Build prerequisites (Arch Linux)

```bash
sudo pacman -S --needed base-devel archiso git qemu-system-x86 edk2-ovmf \
  python rsync openssh squashfs-tools dosfstools mtools syslinux grub refind
```

Build packages as an unprivileged user:

```bash
./scripts/build-packages.sh                 # base kernel included
./scripts/build-packages.sh --skip-kernel   # fast iteration
./scripts/build-packages.sh --with-variants # all scheduler variants
```

Build the ISO as root:

```bash
sudo ./scripts/build-iso.sh
# or
sudo ./mkiso
```

The local `[balikos]` repository is served on `127.0.0.1:8765`; this avoids
file:// paths being unavailable inside the mkarchiso chroot.

## Migration from an installed 1.0 system

The repository does not require a reinstall.  On a 1.0 machine:

```bash
sudo pacman -Syu
# install the BalıkOS packages from the new local/repo mirror
sudo pacman -S balikos-branding balikos-settings balikos-hello \
  balikos-store balikos-updater
sudo systemctl enable --now balikos-updater.timer
```

`pacman -Syu` upgrades `balikos-kernel` in place because it provides/conflicts
with `linux-cachyos`.  Re-run mkinitcpio only if the package requests it:

```bash
sudo mkinitcpio -P
```

`/etc/balikos-release` is updated by the post-update hook after the milestone
packages are installed; a 1.1 ISO is never required for a 1.0 system.

## Verification and limitations

The ISO build, package build and QEMU BIOS/UEFI smoke tests are wired in
`.github/workflows/build.yml`.  The authoring host used for this tree is not
Arch Linux (it has no pacman/makepkg/mkarchiso), so those build steps must be
run on Arch or in the CI container; this is the only reliable acceptance gate
for the binary artifacts.

## Licensing / attribution

The kernel fork retains CachyOS/Arch upstream copyrights, source, config and
patches and remains GPL-2.0-only.  CachyOS is credited here and in the kernel
package metadata as upstream; no CachyOS string is used in the BalıkOS user
interface.  BalıkOS application code is MIT licensed; see each package's
`LICENSE`.
