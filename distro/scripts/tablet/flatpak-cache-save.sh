#!/bin/bash

set -euo pipefail

WORKDIR="${1}"
ROOTDIR="${2}"
CACHE_DIR="${WORKDIR}/build/flatpak-files"
SOURCE_DIR="${ROOTDIR}/var/lib/flatpak"

if [[ -d "${SOURCE_DIR}" ]] && [[ -n "$(ls -A "${SOURCE_DIR}" 2>/dev/null)" ]]; then
    echo "Saving Flatpak data to cache at ${CACHE_DIR}"
    mkdir -p "${CACHE_DIR}"
    cp -a "${SOURCE_DIR}/." "${CACHE_DIR}/"
else
    echo "No Flatpak data found at ${SOURCE_DIR}, skipping cache save"
fi
