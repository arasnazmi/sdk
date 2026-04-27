#!/bin/bash

set -e

MARKER=/var/lib/gdm3/.autologin-configured

[ -f "$MARKER" ] && exit 0

GEMSTONE_UID=$(id -u gemstone 2>/dev/null || echo 1000)
USER_PATH="/org/freedesktop/Accounts/User${GEMSTONE_UID}"

busctl call \
    org.freedesktop.Accounts \
    "${USER_PATH}" \
    org.freedesktop.Accounts.User \
    SetAutomaticLogin b true

mkdir -p /var/lib/gdm3
touch "${MARKER}"
