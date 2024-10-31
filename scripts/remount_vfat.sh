#!/bin/sh -e

################################################################################
# Description: remounts /the_binding in the specified mounted vfat folder to the internal storage
# Author: Vivek Revankar <vivek@master-hax.com>
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

fs_type=$(stat -f -c %T $mounted_drive_path)
if [ "$fs_type" != "msdos" ]; then
    echo "detected filesystem type was not 'msdos', found $fs_type"
    exit 1
fi

drive_binding_dir="$mounted_drive_path/the_binding"
internal_binding_dir="/mnt/runtime/write/emulated/0/the_binding"
mkdir -p -v "$drive_binding_dir"
mkdir -p -v "$internal_binding_dir"
mount \
-t sdcardfs \
-o nosuid,nodev,noexec,noatime,gid=9997 \
"$drive_binding_dir" "$internal_binding_dir"

echo "vfat drive remounted succesfully"