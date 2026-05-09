#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

curl -fsSL https://repo.waydro.id -o /tmp/waydroid.sh
chmod +x /tmp/waydroid.sh
/tmp/waydroid.sh trixie
apt-get update -y
apt-get install -y waydroid
