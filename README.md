EXT to F2FS ROM converter
=============
This is a simple tool for converting EXT4 roms to F2FS.

Supported devices:
-----
* Galaxy S2 Plus (NFC)
* Galaxy S2 Plus (Non-NFC)
* Galaxy Grand Duos

ROM compatibility
-----
Galaxy S2 Plus:
* Paranoid Android (Since 4.5-BETA1)
* PAC-ROM (Since 20140807)
* Dirty Unicorns (Since 20140808)

Galaxy Grand Duos:
* Currently no roms

Usage
-----
Linux:

    cd linux
    chmod +x convert.sh
    ./convert.sh [ROM_NAME].zip

Windows:

    Install cygwin with patch, unzip, zip, wget, cpio, perl and copy files to cygwin home catalog
    cd linux
    chmod +x convert.sh
    ./convert.sh
