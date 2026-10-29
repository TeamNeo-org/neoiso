==========================
NeoOS GNU/Linux (isobuild)
==========================

NeoOS is an Arch Linux based distribution. This repository contains the tooling and profiles used to build
NeoOS installation media (ISO images, netboot artifacts and bootstrap tarballs).

It is a fork of `archiso <https://gitlab.archlinux.org/archlinux/archiso>`_, the official Arch Linux ISO
generator, and is kept close to upstream so that fixes can be pulled in easily. Distribution specific
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

Requirements
============

Building images is only supported on Arch Linux or a derivative (such as NeoOS). Install the tooling with:

.. code:: sh

   pacman -S --needed arch-install-scripts bash dosfstools e2fsprogs erofs-utils gnupg grub jq \
       libarchive libisoburn mtools openssl python-docutils squashfs-tools util-linux zsync

* ``erofs-utils``: only needed for profiles using the ``erofs`` airootfs image type (``configs/baseline``)
* ``grub``: only needed for the ``uefi.grub`` bootmode
* ``python-docutils``: only needed to generate the man page
* ``systemd-ukify``: optional, for embedding AArch64 device tree files
* ``zsync``: optional, for the netboot zsync artifacts
* ``shellcheck``: for ``make check``
* ``edk2-ovmf`` and ``qemu``: for testing images with ``run_archiso``

Building
========

Building as a regular user requires ``unshare(1)`` and user namespace support in the kernel. Running as root is
neither required nor recommended:

.. code:: sh

   ./archiso/mkarchiso configs/releng

The resulting images are written to ``out/`` (e.g. ``neoos-YYYY.MM.DD-x86_64.iso``). Work and output
directories as well as signing options are described in the `mkarchiso(1) <man/mkarchiso.1.rst>`_ man page,
or in ``mkarchiso -h``.

To install the tooling and profiles system-wide:

.. code:: sh

   make install

Testing
=======

The convenience script **run_archiso** boots an image in QEMU. UEFI is the default; pass ``-b`` for BIOS:

.. code:: sh

   ./scripts/run_archiso.sh -i out/neoos-YYYY.MM.DD-x86_64.iso
   ./scripts/run_archiso.sh -b -i out/neoos-YYYY.MM.DD-x86_64.iso

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

Staying in sync with upstream
=============================

Upstream archiso is tracked as the ``upstream`` remote:

.. code:: sh

   git remote add upstream https://gitlab.archlinux.org/archlinux/archiso.git   # once
   git fetch upstream
   git merge upstream/master

Merge rather than rebase, because NeoOS commits are published. This file is the one expected conflict on
nearly every sync, since upstream edits it as well; keep the NeoOS version and fold in new requirements or
documentation changes. Changes to the rebranded boot loader menus and profile definitions usually merge
cleanly, but keep local edits to upstream owned files small for that reason.

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

LLM usage policy
================

LLMs and other AI contributions ARE allowed, as long as:
1. The code is readable and easily changable
2. You know what it did
3. You claim responsibility for your contributions.
