#!/bin/bash

set -euo pipefail

DISTRO_TYPE="${1:-minimal}"

chmod +x /usr/local/bin/gem-camera-setup

if [[ "$DISTRO_TYPE" == "desktop" ]]; then
    chmod +x /usr/local/bin/set-system-keyboard-layout
    chmod +x /usr/local/bin/set-system-language
    chmod +x /usr/local/bin/xfce4-popup-applicationsmenu
fi

if [[ "$DISTRO_TYPE" == "kiosk" ]]; then
    if [[ -f /usr/local/bin/kiosk ]]; then
        chmod +x /usr/local/bin/kiosk
    fi
fi

chown -R gemstone:gemstone /home/gemstone

if [[ "$DISTRO_TYPE" == "tablet" ]]; then
    chmod 0755 /usr/local/sbin/nftables-safe
    chmod 0755 /usr/local/sbin/dpkg

    # Allowlist sadece root tarafindan duzenlenebilsin
    chown root:root /etc/gemstone/allowed-packages.list
    chmod 0644 /etc/gemstone/allowed-packages.list

    # root'un PATH'ine /usr/local/sbin ekle (yoksa)
    grep -qxF 'export PATH="/usr/local/sbin:$PATH"' /root/.bashrc || echo 'export PATH="/usr/local/sbin:$PATH"' >> /root/.bashrc
fi
