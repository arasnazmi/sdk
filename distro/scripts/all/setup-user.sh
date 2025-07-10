#!/bin/bash

set -euo pipefail

adduser \
  --gecos gemstone \
  --disabled-password \
  --shell /bin/bash gemstone

getent group gpio >/dev/null || groupadd gpio
getent group spi >/dev/null || groupadd spi

usermod gemstone -G sudo,dialout,tty,video,i2c,gpio,spi

echo "gemstone:t3" | chpasswd
