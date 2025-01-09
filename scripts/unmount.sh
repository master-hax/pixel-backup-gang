#!/bin/sh -x

################################################################################
# Description: unmounts the block device previously mounted by mount_ext4.sh
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./unmount.sh
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo "not running in global mount namespace, try elevating first"
  exit 1
fi

android_version=$(getprop ro.build.version.release)

if [ $android_version -gt 10 ]; then
  # for Android 11+
  internal_binding_dir="/mnt/pass_through/0/emulated/0/the_binding"
else
  # for Android 10 and below
  internal_binding_dir="/mnt/runtime/write/emulated/0/the_binding"
fi

[[ $(mount | grep -w "$internal_binding_dir") != "" ]] && \
  umount -v $internal_binding_dir

# check if mount exists for EXT4 drives
[[ $(mount | grep -w "/mnt/my_drive") != "" ]] && \
  umount -v /mnt/my_drive
