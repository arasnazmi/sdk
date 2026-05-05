#!/bin/bash

# --- Ayarlar ---
# initrd icine dahil edilmesini istedigin kernel modulleri
MODULES_TO_ADD=(
    "ext4"
    "usb_storage"
    "vfat"
    "dwc2"
    "btrfs"
    "overlay"
    "veth"
    "configfs"
    "fuse"
    "loop"
    "squashfs"
    "cirrus"
    "drm_display_helper"
    "usbtouchscreen"
    "video"
    "virtio_input"
    )

# initrd icine kopyalanmasini istedigin binary (komut) listesi
BINARIES_TO_INCLUDE=(
    "/sbin/ip"
    "/usr/bin/lsblk"
    "/usr/bin/ping"
    "/usr/bin/unl0kr"
    "/usr/sbin/cryptsetup"
    "/usr/sbin/modprobe"
    )

HOOK_FILE="/etc/initramfs-tools/hooks/custom_tools"

# Root kontrolu
if [ "$EUID" -ne 0 ]; then 
  echo "Lutfen bu scripti sudo ile calistirin."
  exit
fi

echo "--- Initramfs Yapilandirmasi Basliyor ---"

# 1. Modulleri /etc/initramfs-tools/modules dosyasina ekle
echo "[*] Moduller ekleniyor..."
for mod in "${MODULES_TO_ADD[@]}"; do
    if ! grep -q "^$mod" /etc/initramfs-tools/modules; then
        echo "$mod" >> /etc/initramfs-tools/modules
        echo "  + $mod eklendi."
    else
        echo "  - $mod zaten mevcut."
    fi
done

# 2. Hook scripti olustur (Binary'leri imaja dahil etmek icin)
echo "[*] Hook scripti olusturuluyor: $HOOK_FILE"
cat << 'EOF' > "$HOOK_FILE"
#!/bin/sh
PREREQ=""
prereqs() {
    echo "$PREREQ"
}

case $1 in
prereqs)
    prereqs
    exit 0
    ;;
esac

. /usr/share/initramfs-tools/hook-functions

# Kullanicinin belirttigi binary'leri kopyala
# Kopyalanacak listeyi asagida script dinamik olarak guncelleyecek
EOF

# Script icindeki binary listesini hook dosyasina isle
for bin in "${BINARIES_TO_INCLUDE[@]}"; do
    if [ -f "$bin" ]; then
        echo "copy_exec $bin" >> "$HOOK_FILE"
        echo "  + $bin hook listesine eklendi."
    else
        echo "  ! Uyari: $bin bulunamadi, atlaniyor."
    fi
done

# 3. Hook scriptine calistirma yetkisi ver
chmod +x "$HOOK_FILE"

# 4. Ana konfigurasyonda sikistirma ayarini kontrol et (Opsiyonel)
# Raspberry Pi bazen hizli acilis icin 'lz4' veya 'gzip' tercih eder.
sed -i 's/^COMPRESS=.*/COMPRESS=gzip/' /etc/initramfs-tools/initramfs.conf

# 5. Initramfs'i Guncelle
echo "[*] Initramfs imaji yeniden olusturuluyor (Bu islem biraz surebilir)..."

update-initramfs -c -k $(uname -r)

echo "--- İslem Tamamlandi ---"
