#!/bin/bash

ROM="$1"

if [ -z "$ROM" ]; then
	echo "[ERROR] Zip name is empty!"; exit
fi

chmod +x tools/*

# Unzipping rom
unzip "$ROM" -d ".rom"

# Patching updater script
patch -p0 < patches/updater-script.patch

# Patching ramdisk
mv .rom/boot.img .
tools/split_boot boot.img
if [ -f "boot/ramdisk/fstab.capri_ss_s2ve" ]; then #s2ve
	cat patches/fstab.patch | sed 's/s2vep/s2ve/g' | patch -p0
        cat patches/init.capri.patch | sed 's/s2vep/s2ve/g' | patch -p0
else
	patch -p0 < patches/fstab.patch
	patch -p0 < patches/init.capri.patch
fi

# Downloading F2FS binaries
wget https://raw.githubusercontent.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/automount -O boot/ramdisk/sbin/automount
wget https://github.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/blob/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/busybox?raw=true -O boot/ramdisk/sbin/busybox

# Repacking ramdisk
cd boot
../tools/repack_ramdisk ramdisk boot.img-ramdisk.cpio.gz
cd ..

# Repacking boot image
tools/mkbootimg --kernel boot/boot.img-kernel --ramdisk boot/boot.img-ramdisk.cpio.gz --pagesize 4096 --base 0xa2000000 --ramdiskaddr 0xa3000000 --cmdline "console=ttyS0,115200n8 mem=832M@0xA2000000 androidboot.console=ttyS0 vc-cma-mem=0/176M@0xCB000000" -o .rom/boot.img

# Repacking rom file
cd .rom
zip -r ../"F2FS-$ROM" .
cd ..

# Cleaning
rm -rf .rom boot

echo "Done! ROM File: F2FS-$ROM"
