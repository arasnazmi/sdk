#!/bin/bash

set -euo pipefail

adduser \
  --gecos gemstone \
  --disabled-password \
  --shell /bin/bash gemstone

usermod gemstone -G sudo,dialout,tty,video,i2c

echo "gemstone:t3" | chpasswd
