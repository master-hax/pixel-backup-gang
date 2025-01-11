#!/bin/sh -ex

################################################################################
# Description: mounts the specified ext4 block device to /the_binding
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./mount_ext4.sh <BLOCK_DEVICE_PATH>
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo "not running in global mount namespace, try elevating first"
  exit 1
fi

mkdir -p -v /mnt/my_drive
mount \
    -t ext4 \
    -o nosuid,nodev,noexec,noatime \
    "$1" /mnt/my_drive

mkdir -p -v /mnt/my_drive/the_binding
chmod -R 777 /mnt/my_drive
chown -R sdcard_rw:sdcard_rw /mnt/my_drive

# may be possible to avoid this by mounting to /mnt/expand/<uuid>
# TODO: use magiskpolicy https://github.com/topjohnwu/Magisk/blob/master/docs/tools.md#magiskpolicy
setenforce 0

mkdir -p -v /mnt/runtime/write/emulated/0/the_binding
mount \
    -t sdcardfs \
    -o nosuid,nodev,noexec,noatime,gid=9997 \
    /mnt/my_drive/the_binding /mnt/runtime/write/emulated/0/the_binding

# TODO: reduce permissions via chmod & sdcardfs mask
