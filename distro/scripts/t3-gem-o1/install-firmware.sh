#!/bin/bash

set -euo pipefail

WORKDIR="$1"
ROOTDIR="$2"

mkdir -p "$ROOTDIR/lib/firmware/ti-connectivity"
cp -f "$WORKDIR/src/wl18xx-fw/"*.bin "$ROOTDIR/lib/firmware/ti-connectivity"
cp -f "$WORKDIR/src/wl18xx-bt-fw/initscripts/TIInit_11.8.32.bts" "$ROOTDIR/lib/firmware/ti-connectivity"

cp -ar "$WORKDIR/src/firmware-o1-edge-ai/"* "$ROOTDIR/lib/firmware"
cd "$ROOTDIR/lib/firmware"
ln -sfn "vision_apps_eaik/vx_app_rtos_linux_c7x_1.out" "j722s-c71_0-fw"
ln -sfn "vision_apps_eaik/vx_app_rtos_linux_c7x_1.out.signed" "j722s-c71_0-fw-sec"
ln -sfn "vision_apps_eaik/vx_app_rtos_linux_c7x_2.out" "j722s-c71_1-fw"
ln -sfn "vision_apps_eaik/vx_app_rtos_linux_c7x_2.out.signed" "j722s-c71_1-fw-sec"
ln -sfn "vision_apps_eaik/vx_app_rtos_linux_mcu2_0.out" "j722s-main-r5f0_0-fw"
ln -sfn "vision_apps_eaik/vx_app_rtos_linux_mcu2_0.out.signed" "j722s-main-r5f0_0-fw-sec"

cp -ar "$WORKDIR/src/ti-img-rogue-umlibs/targetfs/j721s2_linux/lws-generic/release/etc/"* "$ROOTDIR/etc"
cp -ar "$WORKDIR/src/ti-img-rogue-umlibs/targetfs/j721s2_linux/lws-generic/release/usr/"* "$ROOTDIR/usr"
cp -ar "$WORKDIR/src/ti-img-rogue-umlibs/targetfs/j721s2_linux/lws-generic/release/lib/"* "$ROOTDIR/lib"
