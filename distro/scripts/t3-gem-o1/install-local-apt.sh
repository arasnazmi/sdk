#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

MACHINE="t3_gem_o1"
CI="$3"

if [ "$CI" = "true" ]; then
    mkdir -p /etc/apt/sources.list.d
    mkdir -p /etc/apt/keyrings

    curl -fsSL https://packages.t3gemstone.org/apt/gemstone-packages-keyring.gpg -o /etc/apt/keyrings/gemstone-packages-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/gemstone-packages-keyring.gpg] https://packages.t3gemstone.org/apt/t3-gem-o1 bsp main" | tee /etc/apt/sources.list.d/gemstone.list
else
    echo "deb [trusted=yes] http://0.0.0.0:8000/${MACHINE} ./" | tee /etc/apt/sources.list.d/local-apt.list
fi

apt-get update -y
apt-get install -y \
    kernel-module-at24 \
    kernel-module-bluetooth \
    kernel-module-br-netfilter \
    kernel-module-bridge \
    kernel-module-btqca \
    kernel-module-btusb \
    kernel-module-can \
    kernel-module-can-dev \
    kernel-module-can-raw \
    kernel-module-cdc-acm \
    kernel-module-cdns-csi2rx \
    kernel-module-cdns-dphy-rx \
    kernel-module-e5010-jpeg-enc \
    kernel-module-fusb302 \
    kernel-module-gb-usb \
    kernel-module-hci-uart \
    kernel-module-hdc2010 \
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
    kernel-module-loop \
    kernel-module-m-can \
    kernel-module-m-can-platform \
    kernel-module-musb-hdrc \
    kernel-module-nf-nat \
    kernel-module-omap-mailbox \
    kernel-module-overlay \
    kernel-module-panel-raspberrypi-touchscreen \
    kernel-module-panel-simple \
    kernel-module-phy-can-transceiver \
    kernel-module-plusb \
    kernel-module-pwm-fan \
    kernel-module-rpi-panel-attiny-regulator \
    kernel-module-rpmsg-char \
    kernel-module-rpmsg-ctrl \
    kernel-module-rpmsg-ns \
    kernel-module-rpmsg-pru \
    kernel-module-snd-usb-audio \
    kernel-module-spidev \
    kernel-module-tc358762 \
    kernel-module-ti-k3-dsp-remoteproc \
    kernel-module-ti-k3-r5-remoteproc \
    kernel-module-ti-usb-3410-5052 \
    kernel-module-ums-usbat \
    kernel-module-usb-conn-gpio \
    kernel-module-usb-f-acm \
    kernel-module-usb-f-ecm \
    kernel-module-usb-f-ecm-subset \
    kernel-module-usb-f-eem \
    kernel-module-usb-f-fs \
    kernel-module-usb-f-hid \
    kernel-module-usb-f-mass-storage \
    kernel-module-usb-f-ncm \
    kernel-module-usb-f-rndis \
    kernel-module-usb-f-serial \
    kernel-module-usb-f-ss-lb \
    kernel-module-usb-f-uac1 \
    kernel-module-usb-f-uac2 \
    kernel-module-usb-f-uvc \
    kernel-module-usb-serial-simple \
    kernel-module-usb-storage \
    kernel-module-usb-wwan \
    kernel-module-usb3503 \
    kernel-module-usbnet \
    kernel-module-usbserial \
    kernel-module-v4l2-async \
    kernel-module-v4l2-dv-timings \
    kernel-module-v4l2-fwnode \
    kernel-module-v4l2-mem2mem \
    kernel-module-veth \
    kernel-module-videobuf2-v4l2 \
    kernel-module-virtio-rpmsg-bus \
    kernel-module-wl18xx \
    kernel-module-wlcore \
    kernel-module-wlcore-sdio \
    kernel-module-wpanusb \
    kernel-module-xt-addrtype \
    kernel-module-xt-conntrack \
    kernel-module-xt-masquerade \
    kernel-module-xt-nat \
    ti-img-rogue-driver

if [ "$CI" = "true" ]; then
    apt-get install -y \
        gem-t3-gem-o1-bsp \
        kernel-image-image \
        u-boot
fi
