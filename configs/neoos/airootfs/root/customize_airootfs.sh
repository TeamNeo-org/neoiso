#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Runs inside the airootfs chroot after all packages are installed.
# Creates the NeoOS live user that sddm logs into automatically.
set -euo pipefail

liveuser='liveuser'

if ! id -u "${liveuser}" &>/dev/null; then
    useradd --create-home --groups wheel --shell /usr/bin/zsh "${liveuser}"
    passwd --delete "${liveuser}"
fi
