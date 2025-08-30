#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

MACHINE="beagley_ai"
CI="$3"

if [ "$CI" = "true" ]; then
    mkdir -p /etc/apt/sources.list.d
    mkdir -p /etc/apt/keyrings

    curl -fsSL https://packages.t3gemstone.org/apt/gemstone-packages-keyring.gpg -o /etc/apt/keyrings/gemstone-packages-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/gemstone-packages-keyring.gpg] https://packages.t3gemstone.org/apt/beagley-ai bsp main" | tee /etc/apt/sources.list.d/gemstone.list
else
    echo "deb [trusted=yes] http://0.0.0.0:8000/${MACHINE} ./" | tee /etc/apt/sources.list.d/local-apt.list
fi

apt-get update -y
apt-get install -y \
    gemstone-boot-files \
    kernel-image-image \
    kernel-module-at24 \
    kernel-module-bluetooth \
    kernel-module-br-netfilter \
    kernel-module-bridge \
    kernel-module-cc33xx \
    kernel-module-cc33xx-sdio \
    kernel-module-cdc-acm \
    kernel-module-cdns-csi2rx \
    kernel-module-cdns-dphy-rx \
    kernel-module-e5010-jpeg-enc \
    kernel-module-imx219 \
    kernel-module-imx290 \
    kernel-module-imx390 \
    kernel-module-ip6-tables \
    kernel-module-ip6table-filter \
    kernel-module-iptable-filter \
    kernel-module-iptable-mangle \
    kernel-module-iptable-nat \
    kernel-module-iptable-raw \
    kernel-module-iptable-security \
    kernel-module-j721e-csi2rx \
    kernel-module-libcomposite \
    kernel-module-nf-nat \
    kernel-module-omap-mailbox \
    kernel-module-overlay \
    kernel-module-rpmsg-char \
    kernel-module-rpmsg-ctrl \
    kernel-module-rpmsg-ns \
    kernel-module-rpmsg-pru \
    kernel-module-spidev \
    kernel-module-ti-k3-dsp-remoteproc \
    kernel-module-ti-k3-r5-remoteproc \
    kernel-module-u-ether \
    kernel-module-u-serial \
    kernel-module-usb-f-acm \
    kernel-module-usb-f-mass-storage \
    kernel-module-usb-f-rndis \
    kernel-module-veth \
    kernel-module-virtio-rpmsg-bus \
    kernel-module-xt-addrtype \
    kernel-module-xt-conntrack \
    kernel-module-xt-masquerade \
    kernel-module-xt-nat \
    ti-img-rogue-driver \
    u-boot
