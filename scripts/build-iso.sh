#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Compose configs/neoos with a desktop module and build images with mkarchiso.
set -euo pipefail

script_dir=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")
repo_root=$(dirname -- "${script_dir}")
profile_base="${repo_root}/configs/neoos"
mkarchiso="${repo_root}/archiso/mkarchiso"
desktop='plasma'
declare -a mkarchiso_args=()

usage() {
    cat <<EOF
Usage: $(basename -- "$0") [options] [-- <mkarchiso options>]

Options:
  -d, --desktop NAME   desktop module from configs/neoos/desktops (default: plasma; 'none' for console only)
  -l, --list           list available desktop modules and exit
  -h, --help           show this help

Arguments after -- are passed to mkarchiso, e.g.:
  $(basename -- "$0") -d plasma -- -v -w /path/to/work -o /path/to/out
EOF
}

list_desktops() {
    local dir name
    printf '%-12s %s\n' 'none' 'console only (multi-user.target)'
    for dir in "${profile_base}"/desktops/*/; do
        [[ -f "${dir}desktop.conf" ]] || continue
        # shellcheck disable=SC1090
        name=$(source "${dir}desktop.conf" && printf '%s' "${desktop_name:-}")
        printf '%-12s %s\n' "$(basename -- "${dir}")" "${name}"
    done
}

while (( $# )); do
    case "${1}" in
        -d|--desktop)
            if [[ $# -lt 2 ]]; then
                echo "error: ${1} requires an argument" >&2
                exit 1
            fi
            desktop="${2}"
            shift 2
            ;;
        -l|--list)
            list_desktops
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            mkarchiso_args=("$@")
            break
            ;;
        *)
            echo "error: unknown argument '${1}'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

desktop_dir="${profile_base}/desktops/${desktop}"

if [[ "${desktop}" != 'none' && ! -f "${desktop_dir}/desktop.conf" ]]; then
    echo "error: no desktop module '${desktop}' in ${profile_base}/desktops" >&2
    echo "available modules:" >&2
    list_desktops >&2
    exit 1
fi

composed_profile=$(mktemp -d -- "${TMPDIR:-/tmp}/neoos-profile.XXXXXXXX")
trap 'rm -rf -- "${composed_profile}"' EXIT

cp -a -- "${profile_base}/." "${composed_profile}/"
rm -rf -- "${composed_profile}/desktops"

if [[ "${desktop}" == 'none' ]]; then
    iso_application='NeoOS GNU/Linux Rescue'
else
    for arch in x86_64 aarch64; do
        packages="${composed_profile}/packages.${arch}"
        fragment="${desktop_dir}/packages.${arch}"
        [[ -f "${fragment}" ]] || continue
        LC_ALL=C sort -u -- "${packages}" "${fragment}" > "${packages}.merged"
        mv -- "${packages}.merged" "${packages}"
    done

    if [[ -d "${desktop_dir}/airootfs" ]]; then
        cp -a -- "${desktop_dir}/airootfs/." "${composed_profile}/airootfs/"
    fi

    # shellcheck disable=SC1090
    desktop_name=$(source "${desktop_dir}/desktop.conf" && printf '%s' "${desktop_name:-${desktop}}")
    iso_application="NeoOS GNU/Linux Live Desktop (${desktop_name})"
fi

echo "==> desktop module: ${desktop}"
echo "==> ISO application: ${iso_application}"

"${mkarchiso}" -A "${iso_application}" ${mkarchiso_args[@]+"${mkarchiso_args[@]}"} "${composed_profile}"
