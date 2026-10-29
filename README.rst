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

``configs/neoos/``
  The NeoOS base profile: branding, live user, networking and installer tooling (BIOS + UEFI, x86_64 and
  aarch64). It contains no desktop environment; those plug in from ``configs/neoos/desktops/``.

``configs/releng/`` and ``configs/baseline/``
  Upstream archiso profiles, kept unmodified so that syncing with upstream stays conflict-free.
  Use them as references.

``scripts/run_archiso.sh``
  Runs a built ISO in QEMU for testing.

``scripts/build-iso.sh``
  Composes the base profile with a desktop module and builds images with ``mkarchiso``.

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

   ./scripts/build-iso.sh --desktop plasma

The builder copies ``configs/neoos`` to a temporary directory, merges the chosen desktop module into it and
hands the result to ``mkarchiso``; nothing in the base profile is modified. ``--desktop none`` builds a
console rescue image from the same base, and ``--list`` shows the available modules. Extra ``mkarchiso``
options go after ``--``, for example ``-- -v -o /path/to/out``.

The desktop stack dominates the image: with ``plasma``, expect roughly twice the size of the upstream releng
profile and a noticeably longer ``mksquashfs`` run.

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

Desktop modules
===============

A desktop environment is a directory under ``configs/neoos/desktops/`` containing:

* ``desktop.conf``: at least ``desktop_name``, used for the ISO application name
* ``packages.x86_64`` and ``packages.aarch64``: extra packages, merged into the base package lists
* ``airootfs/``: overlay copied on top of the base airootfs, later files win

``plasma`` is the bundled module. To start your own environment, copy the module, replace its overlay and
package lists, and build with ``--desktop <name>``; ``configs/neoos/desktops/README.rst`` documents the full
contract. The base profile stays desktop-agnostic, so swapping a desktop never means editing
``configs/neoos`` itself.

Modules ship display manager enablement declaratively (symlinks in ``graphical.target.wants`` plus
``default.target`` -> ``graphical.target``) and their own autologin configuration, so no build-time
``systemctl enable`` is involved.

Live user
---------

Every module shares one unprivileged account, created at build time by
``configs/neoos/airootfs/root/customize_airootfs.sh``: ``liveuser``, empty password, member of ``wheel``, with
passwordless ``sudo`` via ``airootfs/etc/sudoers.d/10-liveuser``. ``customize_airootfs.sh`` is deprecated by
archiso but still supported, and account creation has no declarative equivalent in ``profiledef.sh``. The root
autologin on tty1 is kept as a console fallback.

Networking
----------

The base profile uses NetworkManager instead of upstream's systemd-networkd + iwd combination, so every
desktop module has a normal network stack to draw on (``plasma`` ships ``plasma-nm`` for the tray applet).
``airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service`` enables it declaratively;
``airootfs/etc/NetworkManager/conf.d/10-neoos.conf`` makes NetworkManager hand DNS to systemd-resolved, which
stays enabled because ``/etc/resolv.conf`` points at its stub resolver.

``--desktop none`` inherits the same stack, so the rescue image can be brought online with ``nmcli`` or
``nmtui``.

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
