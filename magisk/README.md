rooted Magisk module action button based scripts for handling remount processing

Install Steps:
 * copy zip files to download folder of android device
 * Install modules in magisk using modules view
 * reboot

Steps to use
 * Attach drive to phone
 * in Magisk module view press action button to cross mount it.
   * drive is mounted to /mnt/runtime/write/emulated/0/DCIM/Camera/sidemount
  * Whtn done, in Magisk module view press action button to unmount it


NOTES:
  * Pixel Works with FAT32 usb.  does not work with exFAT
  * script DOES initiate a scan intent after mounting

TODO:
  * still need to try to do something to avoid temp storage in photos app beating on flash
