#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

DISTRO_SUITE="${1}"

cat > /etc/apt/sources.list << EOF
## Pardus
deb https://depo.pardus.org.tr/pardus $DISTRO_SUITE main contrib non-free non-free-firmware
# deb-src https://depo.pardus.org.tr/pardus $DISTRO_SUITE main contrib non-free non-free-firmware

## Pardus Deb
deb https://depo.pardus.org.tr/pardus $DISTRO_SUITE-deb main contrib non-free non-free-firmware
# deb-src https://depo.pardus.org.tr/pardus $DISTRO_SUITE-deb main contrib non-free non-free-firmware

## Pardus Security Deb
deb https://depo.pardus.org.tr/guvenlik $DISTRO_SUITE-deb main contrib non-free non-free-firmware
# deb-src https://depo.pardus.org.tr/guvenlik $DISTRO_SUITE-deb main contrib non-free non-free-firmware
EOF

# Pardus 'yirmibes' (Label: Yirmibes) ships pardus1-suffixed gnome-session for
# arm64 but is missing gnome-session-bin / gnome-shell on arm64, so the pardus1
# gnome-session has unsatisfiable deps. Force these packages to come from the
# 'yirmibes-deb' (Debian rebuild) component on arm64.
if [ "$(dpkg --print-architecture)" = "arm64" ]; then
    cat > /etc/apt/preferences.d/pardus-arm64-gnome << 'EOF'
Package: gnome-session gnome-session-bin gnome-session-common gnome-shell gnome-shell-common
Pin: release l=Yirmibes
Pin-Priority: -1
EOF
fi

apt-get update
apt-get install usr-is-merged # see debos PR 361
apt-get upgrade -y
apt-get dist-upgrade -y
