#!/bin/bash

rm -f /boot/initrd.img-* && update-initramfs -c -k $(ls /lib/modules | tail -n 1)
