# pixel backup gang

mount ext4 drives into the google pixel's internal storage

**WARNING: this code is experimental and there is no guarantee that it works. rooting your phone or running any commands as root can be very dangerous. you have been warned.**

## why?

the main goal is to allow for easy backup of external media via Google Photos on original Google Pixel phones, which which have an unlimited storage benefit. the "usual" method is to copy every file to the device's internal storage, which can incur terabytes of unnecessary writes to the limited lifetime of the internal flash memory.

i first tried using FUSE (filesystem in user space) based solutions like [bindfs](https://github.com/mpartel/bindfs) (via [termux root-packages](https://github.com/termux/termux-packages/tree/817ccec622c510929e339285eb5400dbb5b2f4c7/root-packages/bindfs)) and [fuse-nfs](https://github.com/sahlberg/fuse-nfs.git) (complicated to compile for android so i built my own minimal version in Rust). this works and is especially good at sidestepping android's selinux policies. however the performance was not acceptable. (note: i have not tried fbind but i don't think that works out of the box here without using FUSE)

this method is basically a hack around the selinux policies + app permissions using the plain old `mount` command.

(if you don't care about using these scripts and just want to see how it's done, take a look at [mount_ext4.sh](scripts/mount_ext4.sh))

## the good
* works with the stock kernel
* backs up external files larger than 4gb (stock OS only supports FAT32 for external drives)
* reduces wear on internal flash storage
* prevents device from overheating - the external drive gets hot instead

## the bad
* phone needs to be rooted
* there's currently no way to auto-mount when the disk is connected

## the ugly
* there's no GUI, you need to execute shell scripts


anyway here is a demo image of a portable SSD enclosure mounted into the internal storage on my Pixel XL. the data is readable & writable in the Google Photos app.

![image](assets/demo.jpg)

## prerequisites
* a Google Pixel (sailfish) or Google Pixel XL (marlin) on Android 10, rooted with [Magisk](https://github.com/topjohnwu/Magisk). may work on other phones.
* a USB storage drive formatted with an ext4 filesystem. other filesystems not currently supported.

## installation

### via adb (with a PC)
1. install Android Debug Bridge (adb) & connect the pixel
1. clone this repository
1. run `make mobile-install`
   * installs the scripts to `/data/local/tmp` by default
   * if your pixel has Termux installed, you can install the scripts to the Termux home directory with `make mobile-install DEVICE_INSTALL_DIRECTORY=/data/data/com.termux/files/home`
   * if you are running these steps on WSL, you should use the adb executable from windows (which has USB support) with `make mobile-install HOST_ADB_COMMAND=/mnt/c/Users/someone/AppData/Local/Android/Sdk/platform-tools/adb.exe`

### via terminal (on the pixel)
TODO

## usage

### setup
1. start a shell on the device & navigate to the installation directory
    * from the device
      * launch [Terminal](https://android.googlesource.com/platform/packages/apps/Terminal/), [Termux](https://github.com/termux/termux-app), [JuiceSSH](https://play.google.com/store/apps/details?id=com.sonelli.juicessh), or some other terminal app
      * allow sudo access to your terminal app in Magisk
    * from a PC
      * run `adb shell`
      * allow sudo access to the shell process in Magisk
1. run `./start_global_shell.sh` to enter the global mount namespace
    * you may not need this step if you use Magisk to force the global mount namespace

### mounting
1. connect the ext4 formatted external drive to the pixel
   * you should get an os notification that says the drive is not supported
     * if you click on this, it directs you to format the drive in FAT32. you probably don't want to do this
     * you can safely ignore or clear this notification
1. find the block device that you want to mount
   * it is usually at `/dev/block/sdg1` but changes when devices are connected/disconnected
   * if you don't know the filesystem UUID, use `./show_devices.sh`
   * if you know the filesystem UUID, use `./find_device.sh`
1. run `./mount_ext4.sh <BLOCK_DEVICE>`

**everything located under `/the_binding` on the external drive should now be visible by apps at `/the_binding` in the internal storage**

### unmounting

1. make sure nothing important is reading from or writing to the drive
2. run `./unmount.sh`

**everything located under `/the_binding` in the internal storage should now be gone. you can safely disconnect the drive.**

## notes
TODO
