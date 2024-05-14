# pixel backup gang

tools to help backup media via the original google pixel

**WARNING: this code is experimental and there is no guarantee that it works. rooting your phone or running any commands as root can be very dangerous. you have been warned.**

i figured out a way to mount external drives into the pixel's internal storage where it can be seen by installed apps. specifically, google photos. currently only ext4 drives are supported but the same process should work for fat32.

this method requires root access, but otherwise works with the stock kernel.

here is a demo image of a portable SSD enclosure mounted into the internal storage on my Pixel XL:

![image](assets/demo.jpg)

## prerequisites
* a Google Pixel (sailfish) or Google Pixel XL (marlin) on Android 10, rooted with magisk. may work on other phones.
* a USB storage drive formatted with an ext4 filesystem. other filesystems not currently supported.

## installation

### via adb (with a PC)
1. install Android Debug Bridge (adb) & connect the pixel
1. clone this repository
1. run `make mobile-install`
   * installs the scripts to `/data/local/tmp` by default
   * if your pixel has termux installed, you can install the scripts to the tmux home directory with `make mobile-install DEVICE_INSTALL_DIRECTORY=/data/data/com.termux/files/home`
   * if you are running these steps on WSL, you should use the adb executable from windows (which has USB support) with `make mobile-install HOST_ADB_COMMAND=/mnt/c/Users/someone/AppData/Local/Android/Sdk/platform-tools/adb.exe`

### via terminal (on the pixel)
TODO

## usage

1. connect the ext4 formatted external drive to the pixel
   * you should get an os notification that says the drive is not supported
     * if you click on this, it directs you to format the drive in fat32. you probably don't want to do this
     * you can safely ignore or clear this notification
1. start a shell & navigate into the installation directory
  * from the device: launch Termux, AOSP Terminal, or some other terminal app to run the scripts directly from the device
  * from a PC: run `adb shell`

### mounting

1. find the block device that you want to mount
   * it is usually at `/dev/block/sdg1` but changes when devices are connected/disconnected
   * if you don't know the filesystem UUID, use `./show_devices.sh`
   * if you know the filesystem UUID, use `./find_device.sh`
1. run `./mount_ext4 <BLOCK_DEVICE>`

everything located under `/the_binding` on the external drive should now be visible by apps at `/the_binding` in the internal storage

### unmounting

1. make sure nothing important is reading from or writing to the drive
2. run `./unmount`

`/the_binding` should now still be visible to apps in internal storage, but will be empty 

## notes
TODO
