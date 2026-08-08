# mounting network drives (NFS)

mounting an NFS share is a lot more involved than mounting a local drive. the
factory kernel was explicitly compiled without NFS support, and kernel modules
don't work unless they're signed by Google - so we will have to build & flash
our own kernel, baked into a replacement boot.img.

here's roughly where that fits into the pixel's storage layout:

```
marlin-<build>-factory-<hash>.zip  (Google's factory image download)
┌──────────────────────────────────────────────────────────────────────┐
│ bootloader-marlin-<version>.img    (untouched)                       │
├──────────────────────────────────────────────────────────────────────┤
│ radio-marlin-<version>.img         (untouched)                       │
├──────────────────────────────────────────────────────────────────────┤
│ image-marlin-<build>.zip                                             │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ boot.img                         ◄── what we replace (see below) │ │
│ ├──────────────────────────────────────────────────────────────────┤ │
│ │ system.img                       (untouched)                     │ │
│ ├──────────────────────────────────────────────────────────────────┤ │
│ │ vendor.img                       (untouched)                     │ │
│ ├──────────────────────────────────────────────────────────────────┤ │
│ │ cache.img                        (untouched)                     │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

boot.img internal layout
┌────────────────────────────────────────────────────────────────────┐
│ boot header (magic, sizes, load addrs, cmdline)                    │
├────────────────────────────────────────────────────────────────────┤
│ kernel   (Image.lz4-dtb)              ◄── replaced with our kernel │
├────────────────────────────────────────────────────────────────────┤
│ ramdisk  (cpio.gz: init, fstab, ...)  ◄── patched with magisk      │
├────────────────────────────────────────────────────────────────────┤
│ dtb (device tree blob)                (untouched)                  │
└────────────────────────────────────────────────────────────────────┘
```

only `boot.img` will be modified. we will acquire a factory boot.img, swap the
kernel with our own, patch the ramdisk with Magisk, and then finally flash it
to the device.

## prerequisites
* a Google Pixel (sailfish) or Google Pixel XL (marlin). it does not need to
  be rooted but the bootloader must be unlocked
* an NFS server with an export reachable from the pixel over the network

## acquiring the custom boot image
builds are currently supported for marlin versions `QP1A.191005.007.A3` and `QP1A.191005.007.A1` - sailfish support coming soon.

### building it yourself with nix
1. check your device's build number (Settings → About phone → Build number)
1. build it, substituting your device codename (`marlin`, currently the only
   one supported) and build number for `<BUILD_ID>`:
   `nix build 'github:master-hax/pixel-backup-gang#marlin."<BUILD_ID>".magiskBootImages.specialNfs'`
   * e.g. `nix build 'github:master-hax/pixel-backup-gang#marlin."QP1A.191005.007.A3".magiskBootImages.specialNfs'`
   * this produces `result/boot.img`

### downloading a prebuilt boot.img from github
TODO

## flashing the custom boot image

ensure you have `adb` and `fastboot` available from android command-line
tools, then connect to your pixel over USB or wifi/ethernet.

1. reboot the device into the bootloader (`adb reboot bootloader`)
1. flash it: `fastboot flash boot <path to boot.img>`
   * marlin/sailfish have both `boot_a` and `boot_b` partitions - `fastboot
     flash boot` targets whichever slot is currently active
1. reboot: `fastboot reboot`

once it reboots, you should notice two things:
1. an error pops up immediately on the screen saying "There's an internal problem with your device. Contact your manufacturer for details."
1. after a few seconds, if you did not already have the full Magisk app
   installed, the Magisk stub app should pop up in the app drawer and prompt
   you to install the full app - go ahead and do that

if you see both of the above, congratulations! your device now supports NFS.

## setting up the NFS server

TODO

## mounting the NFS share

1. follow [EXTERNAL_DRIVES.md](EXTERNAL_DRIVES.md#setup)'s
   setup steps to get a root shell in the global mount namespace
1. run `./mount_nfs.sh <SERVER> <EXPORT_PATH>` e.g.
   `./mount_nfs.sh 192.168.1.5 /volume1/my_share`

**everything located under `/the_binding` on the NFS export should now be
visible by apps at `/the_binding` in the internal storage**

## automounting on boot

instead of running `mount_nfs.sh` manually after every reboot, install a
Magisk module that does it automatically as root, on every boot, via
`magiskd` - once installed, no root shell or manual mounting is ever needed
again.

1. clone this repository, then build it, substituting your server & export
   path:
   ```
   nix-build -E '
     let d = import ./default.nix {};
     in d.mkNfsAutoMountMagiskModule {
       nfsServer = "192.168.1.5";
       nfsExportPath = "/volume1/my_share";
     }
   '
   ```
   this produces `result/module.zip`
1. install it:
   ```
   adb wait-for-device && adb push result/module.zip /data/local/tmp/module.zip && adb shell su -c 'magisk --install-module /data/local/tmp/module.zip' && adb reboot
   ```

after installing, the module's `service.sh` runs at every boot: it waits for
`sys.boot_completed`, then waits for the NFS server to actually answer a
`ping` (Wi-Fi isn't necessarily up yet that early), then runs `mount_nfs.sh`.

**troubleshooting:** every log line is tagged `pbg:`, so `adb shell su -c 'dmesg | grep pbg'` shows exactly what happened (or didn't) on the last boot.

**uninstalling:** `adb wait-for-device && adb shell su -c 'magisk --remove-modules -n'`

## unmounting

same script as for USB drives - run `./unmount.sh`. see
[EXTERNAL_DRIVES.md](EXTERNAL_DRIVES.md#unmounting).
