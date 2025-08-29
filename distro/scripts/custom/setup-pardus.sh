#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive


wget -c https://depo.pardus.org.tr/pardus/pool/main/p/pardus-archive-keyring/pardus-archive-keyring_2021.1_all.deb -O /tmp/pardus-archive-keyring.deb
dpkg -i /tmp/pardus-archive-keyring.deb
rm /tmp/pardus-archive-keyring.deb

cat > /etc/apt/sources.list << EOF
## Pardus
deb http://depo.pardus.org.tr/pardus yirmiuc main contrib non-free non-free-firmware
# deb-src http://depo.pardus.org.tr/pardus yirmiuc main contrib non-free non-free-firmwar
## Pardus Deb
deb http://depo.pardus.org.tr/pardus yirmiuc-deb main contrib non-free non-free-firmware
# deb-src http://depo.pardus.org.tr/pardus yirmiuc-deb main contrib non-free non-free-firmwar
## Pardus Security Deb
deb http://depo.pardus.org.tr/guvenlik yirmiuc-deb main contrib non-free non-free-firmware
# deb-src http://depo.pardus.org.tr/guvenlik yirmiuc-deb main contrib non-free non-free-firmware
EOF

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y
