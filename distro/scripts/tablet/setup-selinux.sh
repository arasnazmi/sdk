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

# Force permissive on first boot. selinux-policy-default's postinst
# leaves /etc/selinux/config at SELINUX=enforcing, but build-time
# labels are wrong (chroot has no audit netlink so setfiles never runs)
# and enforcing would block essential services before
# gem-selinux-relabel.service has a chance to fix things. The user
# flips this back to enforcing once labels are verified.
if [ -f /etc/selinux/config ]; then
    sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
fi

# Mark the rootfs for relabeling. setfiles cannot run here: the debos
# chroot has no audit netlink, so the call exits silently without
# writing any xattrs. gem-selinux-relabel.service handles the labeling
# on first boot using the running kernel.
touch /.autorelabel
