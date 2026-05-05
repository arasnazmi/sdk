#!/bin/bash

# Host
# $ ./share-network.sh wlp0s20f3 enx02123456789a

# Target
# $ sudo ip route add default via 192.168.7.59 dev usb0

# Target
# $ MACHINE="t3_gem_o1"
# $ MACHINE="corei7-64-intel-common"
# $ echo "deb [trusted=yes] http://192.168.7.2:8000/${MACHINE} ./" | sudo tee /etc/apt/sources.list.d/local-apt.list

INTERNET_IFACE="${1:-wlp0s20f3}"
OTHER_IFACE="${2:-enx02123456789a}"

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -A FORWARD -i $OTHER_IFACE -o $INTERNET_IFACE -j ACCEPT
sudo iptables -A FORWARD -i $INTERNET_IFACE -o $OTHER_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o $INTERNET_IFACE -j MASQUERADE
