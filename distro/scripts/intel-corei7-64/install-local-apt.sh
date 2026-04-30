#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

MACHINE="corei7-64-intel-common"
DISTRO_TYPE="${2:-minimal}"
CI="$3"

if [ "$CI" = "true" ]; then
    mkdir -p /etc/apt/sources.list.d
    mkdir -p /etc/apt/keyrings

    curl -fsSL https://packages.t3gemstone.org/apt/gemstone-packages-keyring.gpg -o /etc/apt/keyrings/gemstone-packages-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/gemstone-packages-keyring.gpg] https://packages.t3gemstone.org/apt/intel-corei7-64 bsp main" | tee /etc/apt/sources.list.d/gemstone.list
else
    echo "deb [trusted=yes] http://0.0.0.0:8000/${MACHINE} ./" | tee /etc/apt/sources.list.d/local-apt.list
fi

apt-get update -y
apt-get install -y \
    kernel \
    kernel-image \
    kernel-module-configfs \
    kernel-module-fuse \
    kernel-module-loop \
    kernel-module-squashfs

if [[ "$DISTRO_TYPE" == "desktop" || "$DISTRO_TYPE" == "gui" || "$DISTRO_TYPE" == "tablet" ]]; then
    apt-get install -y \
        kernel-module-cirrus \
        kernel-module-drm-display-helper \
        kernel-module-usbtouchscreen \
        kernel-module-video \
        kernel-module-virtio-input \
        ;
fi

if [[ "$DISTRO_TYPE" == "tablet" ]]; then
    apt-get install -y \
        kernel-module-fuse \
        kernel-module-ip6-tables \
        kernel-module-iptable-filter \
        kernel-module-iptable-mangle \
        kernel-module-iptable-nat \
        kernel-module-nf-conntrack \
        kernel-module-nf-tables \
        kernel-module-overlay \
        kernel-module-veth \
        kernel-module-xt-checksum \
        kernel-module-xt-masquerade \
        kernel-module-xt-tcpudp \
        ;
fi
