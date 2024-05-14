# pixel backup gang

tools to help backup media via the original google pixel

**WARNING: this code is experimental and there is no guarantee that it works. rooting your phone or running any commands as root can be very dangerous. you have been warned.**

i figured out a way to mount external drives into the pixel's internal storage where it can be seen by installed apps. specifically, google photos. currently only ext4 drives are supported but the same process should work for fat32.

this method requires root access, but otherwise works with the stock kernel.

here is a demo image of a portable SSD enclosure mounted into the internal storage on my Pixel XL:

![image](assets/demo.jpg)

## requirements
* a Google Pixel (sailfish) or Google Pixel XL (marlin) on Android 10, rooted with magisk. may work on other phones.
* an USB storage drive formatted with an ext4 filesystem. other filesystems not currently supported.

## installation

### via adb (with a PC)
1. install Android Debug Bridge (adb) & connect the pixel
1. clone this repository
1. run `make mobile-install`
   * if your pixel has termux installed, you can install the scripts to the tmux home directory with `make mobile-install DEVICE_INSTALL_DIRECTORY=/data/data/com.termux/files/home`
   * if you are running these steps on WSL, you should use the adb executable from windows (which has USB support) with `make mobile-install HOST_ADB_COMMAND=/mnt/c/Users/someone/AppData/Local/Android/Sdk/platform-tools/adb.exe`

### via terminal (on the pixel)
TODO

## usage
TODO

## notes
TODO
