#!/bin/bash

set -euo pipefail

DISTRO_TYPE="${1:-minimal}"

adduser \
  --gecos gemstone \
  --disabled-password \
  --shell /bin/bash gemstone

getent group gpio >/dev/null || groupadd gpio
getent group spi >/dev/null || groupadd spi

usermod gemstone -G sudo,dialout,tty,video,i2c,gpio,spi

if [[ "$DISTRO_TYPE" == "tablet" ]]; then
    echo "gemstone:1447" | chpasswd
else
    echo "gemstone:t3" | chpasswd
fi
