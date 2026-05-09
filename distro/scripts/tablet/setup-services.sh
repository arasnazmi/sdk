#!/bin/bash

systemctl enable nftables.service
systemctl enable phosh.service

systemctl --global enable phosh-lock-on-start.service

# Sudoers drop-in is shipped only with the SELinux overlay.
if [ -f /etc/sudoers.d/default ]; then
    chmod 0440 /etc/sudoers.d/default
fi

chmod +x /usr/local/bin/phosh-lock-on-start

# SELinux pieces — only present when the build set selinux=true.
if [ -f /usr/lib/systemd/system/auditd.service ]; then
    systemctl enable auditd.service
fi

if [ -f /etc/systemd/system/gem-selinux-relabel.service ]; then
    systemctl enable gem-selinux-relabel.service
    chmod +x /usr/local/sbin/gem-selinux-relabel
fi

# Suppress gnome-keyring XDG autostart entries. PAM (libpam-gnome-keyring)
# already starts the daemon at session login and the systemd user units
# socket-activate the components. The XDG entries running in parallel
# spawn extra daemons that race on dbus name registration and trip
# gnome-session's "failed to register before timeout" wait, leaving phosh
# stuck on the loading spinner.
for f in /etc/xdg/autostart/gnome-keyring-*.desktop; do
    [ -f "$f" ] || continue
    grep -q '^Hidden=true' "$f" && continue
    echo 'Hidden=true' >> "$f"
done
