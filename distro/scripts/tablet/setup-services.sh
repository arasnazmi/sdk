#!/bin/bash

systemctl enable nftables.service
systemctl enable auditd.service
systemctl enable phosh.service
systemctl enable gem-selinux-relabel.service

systemctl --global enable phosh-lock-on-start.service

chmod 0440 /etc/sudoers.d/00-tablet

chmod +x /usr/local/bin/phosh-lock-on-start
chmod +x /usr/local/sbin/gem-selinux-relabel

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
