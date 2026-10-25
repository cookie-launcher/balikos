#!/usr/bin/env bash
# shellcheck disable=SC2034
# BalıkOS archiso profile. Version comes from config/balikos-release via
# BALIKOS_VERSION exported by scripts/build-iso.sh.

iso_name="balikos"
iso_label="BALIKOS_${BALIKOS_VERSION//./_}"
iso_publisher="BalıkOS <https://balikos.org>"
iso_application="BalıkOS Live/Installer"
iso_version="${BALIKOS_VERSION:-1.0}"
install_dir="arch"
kernel_params_x86_64="console=ttyS0,115200 systemd.journald.forward_to_console=1 splash"
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
