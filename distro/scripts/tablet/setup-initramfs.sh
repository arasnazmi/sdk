#!/bin/bash

# --- Ayarlar ---
MODULES_TO_ADD=(
    "vfat" "dwc2" "btrfs" "overlay" "veth" "configfs" "fuse" 
    "loop" "squashfs" "cirrus" "drm_display_helper" 
    "usbtouchscreen" "video" "virtio_input" "vc4" "drm" "evdev"
    "psmouse" "atkbd" "hid_generic" "i8042" "virtio_gpu" "bochs"
)

BINARIES_TO_INCLUDE=(
    "/sbin/ip" "/usr/bin/lsblk" "/usr/bin/ping" "/usr/bin/unl0kr" 
    "/usr/sbin/cryptsetup" "/usr/sbin/modprobe"
)

HOOK_FILE="/etc/initramfs-tools/hooks/custom_tools"
BOOT_SCRIPT="/etc/initramfs-tools/scripts/local-top/unl0kr_start"

if [ "$EUID" -ne 0 ]; then 
  echo "Lutfen sudo ile calistirin."
  exit
fi

# 1. Moduller ekleniyor
for mod in "${MODULES_TO_ADD[@]}"; do
    if ! grep -q "^$mod" /etc/initramfs-tools/modules; then
        echo "$mod" >> /etc/initramfs-tools/modules
    fi
done

# 2. Hook Scripti
cat << 'EOF' > "$HOOK_FILE"
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in prereqs) prereqs; exit 0;; esac
. /usr/share/initramfs-tools/hook-functions

# XKB kopyalama
if [ -d /usr/share/X11/xkb ]; then
    mkdir -p "${DESTDIR}/usr/share/X11/xkb"
    cp -a /usr/share/X11/xkb/. "${DESTDIR}/usr/share/X11/xkb/"
fi

# Unl0kr config kopyalama ve temizlik
if [ -f /etc/unl0kr.conf ]; then
    mkdir -p "${DESTDIR}/etc"
    cp /etc/unl0kr.conf "${DESTDIR}/etc"
fi
EOF

for bin in "${BINARIES_TO_INCLUDE[@]}"; do
    if [ -f "$bin" ]; then
        echo "copy_exec $bin" >> "$HOOK_FILE"
    fi
done
chmod +x "$HOOK_FILE"

# 3. Boot Scripti (sifreleme Kontrolu ve Dongu)
cat << 'EOF' > "$BOOT_SCRIPT"
#!/bin/sh
PREREQ="udev"
prereqs() { echo "$PREREQ"; }
case $1 in prereqs) prereqs; exit 0;; esac

ROOT_PART=$(cat /proc/cmdline | tr ' ' '\n' | grep '^root=' | cut -d'=' -f2)

# Modullerin oturmasi icin bekle
sleep 3

IS_LUSKS=$(cryptsetup isLuks "$ROOT_PART" 2>/dev/null && echo "yes" || echo "no")

# --- sifreleme Kontrolu ---
# Eger disk LUKS ile sifrelenmemisse, unl0kr'i calistirmadan cik.
if [ "$IS_LUSKS" = "no" ]; then
    echo "Bilgi: $ROOT_PART sifreli bir disk degil, unl0kr atlaniyor."
fi

# sifre dogru girilene kadar donguye gir
while true; do
    # Kullanicidan sifreyi al (Yuksek DPI ile)
    PASS=$(unl0kr --dpi 192)

    if [ "$IS_LUSKS" != "yes" ]; then
        break
    fi

    if [ -n "$PASS" ]; then
        # cryptsetup ile diski acmayi dene
        if echo "$PASS" | cryptsetup luksOpen "$ROOT_PART" crypt_root; then
            echo "Basarili: Disk acildi."
            break
        else
            echo "Hata: Sifre yanlis, tekrar deneyin."
            sleep 1
        fi
    fi
done
unset PASS
EOF
chmod +x "$BOOT_SCRIPT"

# 4. Guncelleme
sed -i 's/^COMPRESS=.*/COMPRESS=gzip/' /etc/initramfs-tools/initramfs.conf
update-initramfs -c -k $(uname -r)

echo "--- Islem Tamamlandi ---"
