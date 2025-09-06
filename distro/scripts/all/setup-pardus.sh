#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

cat > /etc/apt/sources.list << EOF
## Pardus
deb https://depo.pardus.org.tr/pardus yirmiuc main contrib non-free non-free-firmware
# deb-src https://depo.pardus.org.tr/pardus yirmiuc main contrib non-free non-free-firmware
## Pardus Deb
deb https://depo.pardus.org.tr/pardus yirmiuc-deb main contrib non-free non-free-firmware
# deb-src https://depo.pardus.org.tr/pardus yirmiuc-deb main contrib non-free non-free-firmware
## Pardus Security Deb
deb https://depo.pardus.org.tr/guvenlik yirmiuc-deb main contrib non-free non-free-firmware
# deb-src https://depo.pardus.org.tr/guvenlik yirmiuc-deb main contrib non-free non-free-firmware
EOF

apt-get update
apt-get install usr-is-merged # see debos PR 361
apt-get upgrade -y
apt-get dist-upgrade -y
