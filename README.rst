======================
NeoOS GNU/Linux (isobuild)
======================

NeoOS is an Arch Linux based distribution. This repository contains the tooling and profiles used to build
NeoOS installation media.

It is a fork of `archiso <https://gitlab.archlinux.org/archlinux/archiso>`_, the official Arch Linux ISO
generator, and is kept close to upstream so that fixes can be pulled in easily. The distribution specific
customization lives in the profiles under ``configs/``.

Repository layout
=================

``archiso/mkarchiso``
  The ISO/bootable image builder. Builds ISOs, netboot artifacts and bootstrap tarballs, optionally signing them.

``configs/releng/``
  The full NeoOS live/install profile (BIOS + UEFI, x86_64 and aarch64).

``configs/baseline/``
  A minimal profile with no extra packages, useful as a starting point for new NeoOS flavors.

``scripts/run_archiso.sh``
  Runs a built ISO in QEMU for testing.

``docs/``
  Documentation on writing profiles (``README.profile.rst``) and writing images to bootable media
  (``README.transfer.rst``).

Building
========

NeoOS images are built with ``mkarchiso``. Building as a regular user requires ``unshare(1)`` and user
namespace support in the kernel:

.. code:: sh

   sudo pacman -S --needed arch-install-scripts bash dosfstools e2fsprogs erofs-utils gnupg grub jq \
       libarchive libisoburn mtools openssl python-docutils squashfs-tools zsync
   ./archiso/mkarchiso configs/releng

The resulting images are written to ``out/`` (``neoos-YYYY.MM.DD-x86_64.iso`` and friends).

To install the tooling and profiles system-wide:

.. code:: sh

   make install

Branding
========

Distribution identity is defined in a small number of places:

``configs/<profile>/profiledef.sh``
  ``iso_name``, ``iso_label`` (``NEOS_YYYYMM``), ``iso_publisher`` and ``iso_application``.

``configs/<profile>/airootfs/etc/os-release``
  ``NAME``/``PRETTY_NAME`` are ``NeoOS GNU/Linux``, ``ID=neoos``, ``ID_LIKE=arch``.

``configs/<profile>/airootfs/etc/{issue,motd,hostname}``
  Console login banner, message of the day and live environment hostname.

``configs/<profile>/{grub,syslinux,efiboot}/``
  Boot loader menu titles and help texts.

Names that refer to Arch infrastructure or Arch packages (mirror URLs, ``archlinux-keyring``,
``pacman-key --populate archlinux``, ``arch-install-scripts``, ``archisobasedir``/``archisolabel`` kernel
parameters) are intentionally left unchanged because they are functional, not branding.

Relationship to Arch Linux
==========================

NeoOS is an independent project and is not affiliated with or endorsed by Arch Linux. It uses the Arch Linux
package repositories and therefore distributes packages built by Arch Linux; see the Arch Linux
`trademark policy <https://wiki.archlinux.org/title/DeveloperWiki:TrademarkPolicy>`_ and licensing terms
before redistributing anything built here.

License
=======

GPL-3.0-or-later. See ``LICENSE``. archiso is copyright its contributors; NeoOS additions are copyright the
NeoOS project.
