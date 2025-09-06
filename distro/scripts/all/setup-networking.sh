#!/bin/bash

set -euo pipefail

MACHINE="${1}"
DISTRO_SUITE="${2}"

# Manage all network interfaces
rm -f /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf

# Networkmanager does not allow bad permission
if [ -f /etc/NetworkManager/system-connections/eth0-dhcp.nmconnection ]; then
    chmod 0600 /etc/NetworkManager/system-connections/eth0-dhcp.nmconnection
fi

# Networkmanager does not allow bad permission
if [ -f /etc/NetworkManager/system-connections/usb0.nmconnection ]; then
    chmod 0600 /etc/NetworkManager/system-connections/usb0.nmconnection
fi

# Network management
systemctl enable NetworkManager

# DNS resolving
if [[ "$DISTRO_SUITE" == "noble" || "$DISTRO_SUITE" == "bookworm" || "$DISTRO_SUITE" ==  "yirmiuc-deb" ]]; then
    systemctl enable systemd-resolved
fi

# NTP client
systemctl enable systemd-timesyncd

# Docker needs legacy iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy || true
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true
