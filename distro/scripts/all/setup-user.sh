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
    echo "gemstone:4380" | chpasswd
else
    echo "gemstone:t3" | chpasswd
fi

localedef -i en_US -i tr_TR -f UTF-8 en_US.UTF-8

if [[ "$DISTRO_TYPE" == "tablet" ]]; then
    usermod gemstone -G render &>/dev/null || true
    locale-gen tr_TR.UTF-8
fi
