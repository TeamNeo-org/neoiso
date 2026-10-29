============================
NeoOS desktop modules
============================

A desktop module lives under ``configs/neoos/desktops/`` and contributes a graphical environment on top of
the NeoOS base profile. ``scripts/build-iso.sh`` merges the selected module into a temporary copy of
``configs/neoos`` and passes that to ``mkarchiso``, so adding, replacing or removing a desktop never requires
touching the base profile.

Available modules: ``plasma``. The special name ``none`` builds the base profile as a console rescue image.

Module layout
=============

``<desktop>/desktop.conf``
  Shell snippet with at least ``desktop_name="..."``. Used for the ISO application name and ``--list`` output.

``<desktop>/packages.x86_64``, ``<desktop>/packages.aarch64``
  Extra packages for that architecture, merged (sorted, de-duplicated) into the base package lists.

``<desktop>/airootfs/``
  Overlay applied on top of the base ``airootfs``; files here win. Use it for display manager units, session
  configuration and desktop specific defaults.

The base profile stays desktop-agnostic
=======================================

``configs/neoos/packages.*`` and ``configs/neoos/airootfs`` contain no desktop packages and no display
manager. That is what makes ``--desktop none`` and a future in-house desktop environment equally cheap: the
base provides the live system, the live user, networking and the installer tooling, and the module decides
what starts on top of it.

Writing your own desktop environment
====================================

.. code:: sh

   cp -a configs/neoos/desktops/plasma configs/neoos/desktops/myde
   rm -rf configs/neoos/desktops/myde/airootfs
   # add packages and your own overlay, then:
   ./scripts/build-iso.sh --desktop myde

Nothing outside ``configs/neoos/desktops/myde`` has to change.

What a module usually provides
------------------------------

* the packages: compositor/DE, display manager, fonts, audio stack, browser, network applet
* display manager enablement, declaratively:
  ``airootfs/etc/systemd/system/graphical.target.wants/<dm>.service`` as a symlink to
  ``/usr/lib/systemd/system/<dm>.service``, plus
  ``airootfs/etc/systemd/system/default.target`` -> ``/usr/lib/systemd/system/graphical.target``
* autologin for the unprivileged ``liveuser`` (for sddm: ``airootfs/etc/sddm.conf.d/``)

If your desktop environment brings its own session launcher instead of a display manager, drop those
symlinks and ship its unit or session script in the overlay instead. The live user itself is created by the
base profile, so every module can rely on ``liveuser`` existing with passwordless ``sudo``.
