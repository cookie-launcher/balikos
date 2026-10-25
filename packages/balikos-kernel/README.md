# balikos-kernel

Fork of the upstream CachyOS `linux-cachyos` PKGBUILD.  The source tarball,
kernel configuration, scheduler selection, patches and build options are kept
identical.  Only the package/base name and the kernel localversion suffix are
changed (`cachyos` → `balikos`) so `uname -r` reports a BalıkOS kernel.

Upstream: https://github.com/CachyOS/linux-cachyos
License: GPL-2.0-only (see the upstream source and `$pkgdir/usr/share/licenses`).

A kernel bump is: update `pkgver`/`_tagrel` in this PKGBUILD to the upstream
values and rebuild.  Do not edit the config or patch list during a bump.
