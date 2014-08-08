@echo off

set ROM="%1"

GOTO error_3

IF [%ROM%] == [] GOTO error_1

NET SESSION >nul 2>&1
IF NOT %ERRORLEVEL% == 0 GOTO error_2

:: Unzipping rom
tools\unzip -o "%ROM%" -d ".rom"

:: Patching updater script
tools\patch -p0 < patches/updater-script.patch

:: Pathing boot img
move .rom/boot.img .
tools\bootimg --unpack-bootimg

tools\patch -p0 < patches\cpiolist.patch
if exist {initrd\fstab.capri_ss_s2ve} (
	type patches/fstab.patch | tools\sed 's/s2vep/s2ve/g' | tools\patch -p0
	type patches/init.capri.patch | tools\sed 's/s2vep/s2ve/g' | tools\patch -p0
) else (
	tools\patch -p0 < patches\fstab.patch
	tools\patch -p0 < patches\init.capri.patch
)

:: Downloading F2FS binaries
tools\wget https://raw.githubusercontent.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/automount -O initrd\sbin\automount
tools\wget https://github.com/SamsungBCM-Cyanogenmod/android_device_samsung_s2vep/blob/9efea0c9dcb970c1ca9ab3b6c1a38d115fe76b33/ramdisk/sbin/busybox?raw=true -O initrd\sbin\busybox

:: Repacking boot img
tools\bootimg --repack-bootimg
move boot-new.img .rom/boot.img
del /Q boot-old.img

:: Repacking rom file
cd .rom
..\tools\zip -r ..\F2FS-%ROM% .
cd ..

:: Cleaning
rmdir /s /q .rom boot

echo Done! ROM File: F2FS-%ROM%

goto done

:error_1
echo [ERROR] Zip name is empty
goto done

:error_2
echo [ERROR] Admin rights are required
goto done

:error_3
echo [ERROR] Windows version is currently broken, please use Linux version with Cygwin
goto done

:done
pause >nul
