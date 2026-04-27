#!/bin/bash

set -euo pipefail

WORKDIR="${1}"
ROOTDIR="${2}"
CACHE_DIR="${WORKDIR}/build/flatpak-files"
TARGET_DIR="${ROOTDIR}/var/lib/flatpak"

if [[ -d "${CACHE_DIR}" ]] && [[ -n "$(ls -A "${CACHE_DIR}" 2>/dev/null)" ]]; then
    echo "Flatpak cache found, restoring to ${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"
    cp -a "${CACHE_DIR}/." "${TARGET_DIR}/"
else
    echo "No Flatpak cache found at ${CACHE_DIR}, will download fresh"
fi
