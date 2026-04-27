#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Disable AppArmor - cannot run simultaneously with SELinux as primary LSM
systemctl disable apparmor 2>/dev/null || true

# x86/GRUB
if [ -f /etc/default/grub ]; then
    if ! grep -q 'selinux=1' /etc/default/grub; then
        sed -i 's/^\(GRUB_CMDLINE_LINUX="[^"]*\)"/\1 security=selinux selinux=1"/' /etc/default/grub
        update-grub 2>/dev/null || true
    fi
fi

# ARM / extlinux
for conf in /boot/extlinux/extlinux.conf /boot/extlinux.conf; do
    if [ -f "$conf" ] && ! grep -q 'selinux=1' "$conf"; then
        sed -i '/^\s*APPEND/ s/$/ security=selinux selinux=1/' "$conf"
    fi
done

# Trigger full filesystem relabeling on first boot
touch /.autorelabel
