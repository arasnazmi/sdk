#!/bin/bash

set -euo pipefail

WORKDIR="$1"
ROOTDIR="$2"

DIR_IMGS="$WORKDIR/build/tmp-musl/deploy/images/intel-corei7-64"

mkdir -p "$ROOTDIR/boot"
cp "$DIR_IMGS/bzImage-intel-corei7-64.bin" "$ROOTDIR/boot/bzImage"
