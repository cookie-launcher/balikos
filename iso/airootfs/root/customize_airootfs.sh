if [ -f /usr/share/balikos/overlay.tar ]; then
    tar -xf /usr/share/balikos/overlay.tar -C /
    rm -f /usr/share/balikos/overlay.tar
fi

#!/usr/bin/env bash
# BalıkOS live ISO customization. Run by mkarchiso inside the airootfs chroot.
set -euo pipefail

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8

# Locale / console / hostname
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=us\nFONT=LatArCyrHeb-16\n' > /etc/vconsole.conf
printf 'balikos\n' > /etc/hostname
locale-gen
chmod 0400 /etc/shadow /etc/gshadow 2>/dev/null || true
chmod 0750 /root

# A stable first-boot machine id prevents systemd-firstboot from taking over tty1.
if ! grep -qE '^[0-9a-f]{32}$' /etc/machine-id 2>/dev/null; then
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi
chmod 444 /etc/machine-id
systemctl mask systemd-firstboot.service >/dev/null 2>&1 || true

# Live user (password: live, passwordless sudo). Root remains locked.
if ! id liveuser >/dev/null 2>&1; then
    useradd -m -G wheel,video,render,audio,input,storage -s /bin/bash liveuser
fi
usermod -p "$(openssl passwd -6 -salt balikos live)" liveuser
install -d -m 0750 /etc/sudoers.d
printf 'liveuser ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10-liveuser
chmod 0440 /etc/sudoers.d/10-liveuser

# Enable the graphical live session and networking.
systemctl enable gdm.service >/dev/null 2>&1 || true
systemctl set-default graphical.target >/dev/null 2>&1 || true
systemctl enable NetworkManager.service >/dev/null 2>&1 || true

# BalıkOS update checks are opt-out; the live ISO enables the timer.
systemctl enable balikos-updater.timer >/dev/null 2>&1 || true

# Plymouth: the working BalıkOS frame set is installed as cachyos-bootanimation.
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme cachyos-bootanimation
fi

# Branding release file is the single source of truth, copied from the repo.
if [ -f /etc/balikos-release ]; then
    chmod 644 /etc/balikos-release
fi

# Normalize permissions that archiso's file_permissions does not cover.
chmod 0440 /etc/sudoers.d/10-liveuser
chmod 0755 /etc/calamares/scripts/install-balikos-* 2>/dev/null || true
