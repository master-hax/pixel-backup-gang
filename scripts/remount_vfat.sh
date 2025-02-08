#!/bin/sh -e

################################################################################
# Description: remounts /the_binding in the specified mounted vfat folder to the internal storage
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./remount_vfat.sh <DIRECTORY_PATH>
# Example: ./remount_vfat.sh /mnt/media_rw/2IDK-11F4
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo "not running in global mount namespace, try elevating first"
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /mnt/media_rw/<label>" >&2
  exit 1
fi

mounted_drive_path=$1
if [ ! -e "$mounted_drive_path" ]; then
  echo "directory was not found"
  exit 1
fi
if [ ! -d "$mounted_drive_path" ]; then
  echo "path was not a directory"
  exit 1
fi

fs_type=$(stat -f -c %T "$mounted_drive_path")
if [ "$fs_type" != "msdos" ] && [ "$fs_type" != "vfat" ]; then
    echo "detected filesystem type was not 'msdos' or 'vfat', found $fs_type"
    exit 1
fi

android_version=$(getprop ro.build.version.release)

drive_binding_dir="$mounted_drive_path/the_binding"
if [ "$android_version" -gt 10 ]; then
  # for Android 11+
  internal_binding_dir="/mnt/pass_through/0/emulated/0/the_binding"
else
  # for Android 10 and below
  internal_binding_dir="/mnt/runtime/write/emulated/0/the_binding"
fi
# create mount points and binding directory
mkdir -p -v "$drive_binding_dir"
mkdir -p -v "$internal_binding_dir"

if [ "$android_version" -gt 10 ]; then
mount \
  "$drive_binding_dir" "$internal_binding_dir"
else
mount \
  -t sdcardfs \
  -o nosuid,nodev,noexec,noatime,gid=9997 \
  "$drive_binding_dir" "$internal_binding_dir"
fi

# broadcast the mounted directory to media scanner
am broadcast \
  -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d file:///storage/emulated/0/the_binding/

echo "vfat drive remounted succesfully"
