# mounting

## prerequisites
* a Google Pixel (sailfish) or Google Pixel XL (marlin) on Android 10, rooted with [Magisk](https://github.com/topjohnwu/Magisk). may work on other phones with other versions of android (see https://github.com/master-hax/pixel-backup-gang/pull/33).
* a USB storage drive formatted with an ext4 or FAT32 filesystem.

### formatting a drive as ext4 (for macOS)
first install `e2fsprogs` with `brew install e2fsprogs`

then find your drive mount with `diskutil list`

finally format as ext4 with this command (change the name and target disk)
```
sudo $(brew --prefix e2fsprogs)/sbin/mkfs.ext4 -L "NAME_OF_DRIVE" -O ^metadata_csum,^64bit /dev/TARGET_DISK
```

## installation
installation is essentially just copying the scripts to the device & making them executable. you can do this manually, or use one of the automated steps below. you also probably want to disable [Google Play Protect](https://developers.google.com/android/play-protect) scanning in the Play Store menu.

### from internet via pixel terminal (more convenient, doesn't require a separate computer, but a little sus)
1. start a terminal application and navigate to the directory where you want to install the scripts
1. run the following command:

```sh -c "$(curl -fSs https://raw.githubusercontent.com/master-hax/pixel-backup-gang/install/install.sh)"```

this one-liner runs a small installer script that downloads the latest release archive from github, unpacks it, then makes the contents executable. the current install script can be viewed [here](https://github.com/master-hax/pixel-backup-gang/blob/install/install.sh). piping strange scripts from the web into a root shell is generally not a good idea, but it is convenient. try not to make a habit of it. 😅

### from local repository via adb (preferred, works offline, allows changes, more secure, but requires a separate computer running Linux)
1. install the following software: `adb make shellcheck tar` (requires a separate computer running Linux or Windows Subsystem for Linux)
1. clone this repository (at the desired tag or commit)
1. run `make mobile-install` from the repository root. this installs the scripts to `/data/local/tmp` on the connected android device by default.
   * if your pixel has Termux installed, you can install the scripts to the Termux home directory with `make mobile-install DEVICE_INSTALL_DIRECTORY=/data/data/com.termux/files/home`
   * if you are running these steps on WSL, you should use the adb executable from windows (which has USB support) with `make mobile-install HOST_ADB_COMMAND=/mnt/c/Users/someone/AppData/Local/Android/Sdk/platform-tools/adb.exe`

this is the preferred installation method for development as it doesn't require an internet connection & any changes to the scripts in the local repo are immediately deployed to the pixel

> [!NOTE]  
> The directories `/data/local/tmp` & `/data/data/com.termux/files/home` are known to have less restrictive selinux policies, which allow files to be made executable. Installing the scripts to other directories may not work.

## setup
1. start a shell on the device & navigate to the installation directory
    * from the device
      * launch [Terminal](https://android.googlesource.com/platform/packages/apps/Terminal/), [Termux](https://github.com/termux/termux-app), [JuiceSSH](https://play.google.com/store/apps/details?id=com.sonelli.juicessh), or some other terminal app
      * run `su` then allow sudo access to your terminal app in Magisk
    * from a PC
      * run `adb shell`
      * run `su` then allow sudo access to the shell process in Magisk
1. run `cd` to navigate to the installation directory e.g. `cd ./pixel-backup-gang` or `cd /data/data/com.termux/files/home/pixel-backup-gang` or `cd /data/local/tmp/pixel-backup-gang`
1. run `./start_global_shell.sh` to enter the global mount namespace
    * the Magisk "force the global mount namespace" doesn't work - maybe it only works for magisk modules?

## mounting a drive

### ext4 (i prefer this because i have files larger than 4gb & ext4 is just [better than FAT32](https://en.wikipedia.org/wiki/Comparison_of_file_systems))
1. connect the ext4 formatted external drive to the pixel. you should get an os notification that says the drive is not supported. clear or ignore this notification.
   * this notification directs you to format the drive in FAT32 - don't do that
1. find the block device that you want to mount. it is usually found at `/dev/block/sdg1` but changes when devices are connected and disconnected e.g. it might show up as `/dev/block/sdh1` when reconnected. run `ls -alh /dev/block/` to see what is in there.
   * if you don't know the filesystem UUID, you can use `./show_devices.sh`. this is just a convenience script, you don't need to run this.
   * if you know the filesystem UUID, you can use `./find_device.sh`. this is just a convenience script, you don't need to run this.
1. run `./mount_ext4.sh <BLOCK_DEVICE>` e.g. `./mount_ext4.sh /dev/block/sdg1`

the `mount_ext4.sh` script relabels the drive's files as `media_rw_data_file` (the same [selinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux) type used by real internal storage), so apps can read/write them without disabling selinux enforcement. see [issue #13](https://github.com/master-hax/pixel-backup-gang/issues/13).

### FAT32 (when you only have files < 4gb and/or are a Windows only user unwilling to install a tool like [Ext4Fsd](https://github.com/bobranten/Ext4Fsd.git) and/or are transferring directly from some kind of capture device)
1. connect the FAT32 formatted external drive to the pixel. it should be working normally as removable storage i.e. readable & writable by apps with permission.
1. find the name of folder that the drive is mounted to. it looks like `/mnt/media_rw/2IDK-11F4` - you can check the path displayed in any file explorer app.
1. run `./remount_vfat.sh <MOUNTED_FOLDER>` e.g. `./remount_vfat.sh /mnt/media_rw/2IDK-11F4`

**everything located under `/the_binding` on the external drive should now be visible by apps at `/the_binding` in the internal storage** (the directories are automatically created if they don't already exist)

> [!NOTE]  
> Google Photos will not instantly pick up the new media. It scans the filesystem to update their library when it wants to.
> However, we send a media scan broadcast when the drive is mounted ([ext4](https://github.com/master-hax/pixel-backup-gang/blob/87a0fcc2d4481a54e5c8750bfbf2be8fcee0f50d/scripts/mount_ext4.sh#L52-L54),[VFAT](https://github.com/master-hax/pixel-backup-gang/blob/87a0fcc2d4481a54e5c8750bfbf2be8fcee0f50d/scripts/remount_vfat.sh#L60-L63))
> this is reported to be reliable to get photos to do a scan, however you may need to force close then re-open Google Photos

## unmounting
1. make sure nothing important is reading from or writing to the drive
1. run `./unmount.sh`

**everything located under `/the_binding` in the internal storage should now be gone. you can disconnect the drive if you're sure all pending writes have been flushed.**
