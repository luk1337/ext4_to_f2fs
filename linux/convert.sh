#!/bin/bash

ROM="$1"
DPI="$2"

if [ "$(whereis cpio)" = "cpio:" ]; then echo "[ERROR] cpio is not installed"; ERROR=1; fi
if [ "$(whereis perl)" = "perl:" ]; then echo "[ERROR] perl is not installed"; ERROR=1; fi
if [ "$(whereis zip)" = "zip:" ]; then echo "[ERROR] zip is not installed"; ERROR=1; fi
if [ "$(whereis unzip)" = "unzip:" ]; then echo "[ERROR] unzip is not installed"; ERROR=1; fi
if [ "$(whereis wget)" = "wget:" ]; then echo "[ERROR] wget is not installed"; ERROR=1; fi
if [ "$(whereis patch)" = "patch:" ]; then echo "[ERROR] wget is not installed"; ERROR=1; fi

if [ "$ERROR" = "1" ]; then exit; fi

if [ -z "$ROM" ]; then
	echo "[ERROR] Zip name is empty!"; exit
fi

chmod +x tools/*

# Unzipping rom
unzip -o "$ROM" -d ".rom"

# Set dpi
if [ ! -z "$DPI" ]; then
	sed -i "s/density=240/density=$DPI/g" .rom/system/build.prop
fi

# Collect some useful informations
temp=`od -A n -H -j 20 -N 4 .rom/boot.img | sed 's/ //g'`
ramdisk_load_addr=0x$temp
cmd_line=`od -A n --strings -j 64 -N 512 .rom/boot.img`
base_temp=`od -A n -h -j 14 -N 2 .rom/boot.img | sed 's/ //g'`
zeros=0000
base=0x$base_temp$zeros
page_size=`od -A n -D -j 36 -N 4 .rom/boot.img | sed 's/ //g'`

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
	cp patches/baffin_f2fs/kernel boot/boot.img-kernel
	cp -R patches/baffin_f2fs/modules .rom/system/
else
	echo "[ERROR] Device/ROM is not compatible"
	rm -rf .rom boot
	exit
fi

# Copy automount script
cp patches/automount boot/ramdisk/sbin/automount

# Downloading F2FS binaries
wget https://github.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/blob/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/busybox?raw=true -O boot/ramdisk/sbin/busybox

# Repacking ramdisk
cd boot
../tools/repack_ramdisk ramdisk boot.img-ramdisk.cpio.gz
cd ..

# Repacking boot image
if [ `uname -o` = "Cygwin" ]; then
	tools/mkbootimg.exe --kernel boot/boot.img-kernel --ramdisk boot/boot.img-ramdisk.cpio.gz --pagesize "$page_size" --base "$base" --cmdline "$cmd_line" -o .rom/boot.img
else
	tools/mkbootimg --kernel boot/boot.img-kernel --ramdisk boot/boot.img-ramdisk.cpio.gz --pagesize "$page_size" --base "$base" --cmdline "$cmd_line" -o .rom/boot.img
fi

# Repacking rom file
cd .rom
zip -r ../"F2FS-$ROM" .
cd ..

# Cleaning
rm -rf .rom boot

echo "Done! ROM File: F2FS-$ROM"
