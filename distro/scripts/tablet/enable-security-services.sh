#!/bin/bash

# systemctl enable nftables.service
# systemctl enable auditd.service

systemctl enable tablet-autologin.service
systemctl enable phosh-lock-on-start.service

chmod 0440 /etc/sudoers.d/00-tablet

chmod +x /usr/local/sbin/tablet-autologin.sh
chmod +x /usr/local/bin/phosh-lock-on-start
