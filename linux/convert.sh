#!/bin/bash

ROM="$1"

if [ -z "$ROM" ]; then
	echo "[ERROR] Zip name is empty!"; exit
fi

chmod +x tools/*

# Unzipping rom
unzip -o "$ROM" -d ".rom"

# Patching updater script

sed -i 's/mount("ext4", "EMMC", "\/dev\/block\/mmcblk0p19", "\/system");/run_program("\/sbin\/busybox", "mount", "\/system");/g' .rom/META-INF/com/google/android/updater-script
sed -i 's/format("ext4", "EMMC", "\/dev\/block\/mmcblk0p19", "0", "\/system");/run_program("\/sbin\/mkfs.f2fs", "\/dev\/block\/mmcblk0p19");/g' .rom/META-INF/com/google/android/updater-script
sed -i 's/mount("ext4", "EMMC", "\/dev\/block\/mmcblk0p21", "\/data");/run_program("\/sbin\/busybox", "mount", "\/data");/g' .rom/META-INF/com/google/android/updater-script

# Patching ramdisk
mv .rom/boot.img .
tools/split_boot boot.img
rm -rf boot.img
if [ -f "boot/ramdisk/fstab.capri_ss_s2vep" ]; then #s2vep
	patch -p0 < patches/fstab.patch
	patch -p0 < patches/init.capri.patch
elif [ -f "boot/ramdisk/fstab.capri_ss_s2ve" ]; then #s2ve
	cat patches/fstab.patch | sed 's/s2vep/s2ve/g' | patch -p0
	cat patches/init.capri.patch | sed 's/s2vep/s2ve/g' | patch -p0
elif [ -f "boot/ramdisk/fstab.capri_ss_baffin" ]; then #baffin
	patch -p0 < patches/fstab_i9082.patch
	patch -p0 < patches/init.capri_i9082.patch
	rm -rf boot/boot.img-kernel
	cp patches/baffin_f2fs boot/boot.img-kernel
else
	echo "[ERROR] Device/ROM is not compatible"
	rm -rf .rom boot
	exit
fi

# Downloading F2FS binaries
wget https://raw.githubusercontent.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/automount -O boot/ramdisk/sbin/automount
wget https://github.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/blob/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/busybox?raw=true -O boot/ramdisk/sbin/busybox

# Repacking ramdisk
cd boot
../tools/repack_ramdisk ramdisk boot.img-ramdisk.cpio.gz
cd ..

# Repacking boot image
if [ `uname -o` = "Cygwin" ]; then
	tools/mkbootimg.exe --kernel boot/boot.img-kernel --ramdisk boot/boot.img-ramdisk.cpio.gz --pagesize 4096 --base 0xa2000000 --cmdline "console=ttyS0,115200n8 mem=832M@0xA2000000 androidboot.console=ttyS0 vc-cma-mem=0/176M@0xCB000000" -o .rom/boot.img
else
	tools/mkbootimg --kernel boot/boot.img-kernel --ramdisk boot/boot.img-ramdisk.cpio.gz --pagesize 4096 --base 0xa2000000 --ramdiskaddr 0xa3000000 --cmdline "console=ttyS0,115200n8 mem=832M@0xA2000000 androidboot.console=ttyS0 vc-cma-mem=0/176M@0xCB000000" -o .rom/boot.img
fi

# Repacking rom file
cd .rom
zip -r ../"F2FS-$ROM" .
cd ..

# Cleaning
rm -rf .rom boot

echo "Done! ROM File: F2FS-$ROM"
