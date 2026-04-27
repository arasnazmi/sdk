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

apt-get update
apt-get install usr-is-merged # see debos PR 361
apt-get upgrade -y
apt-get dist-upgrade -y
