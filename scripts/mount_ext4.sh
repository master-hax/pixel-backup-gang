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

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /dev/block/<label> e.g. $0 /dev/block/sdg1" >&2
  exit 1
fi

ext4_blockdev_path=$1

fs_type=$(stat -f -c %T "$ext4_blockdev_path")
if [ "$fs_type" != "tmpfs" ]; then
    echo "detected filesystem type was not 'tmpfs', found $fs_type"
    exit 1
fi

drive_mount_dir='/mnt/my_drive'
internal_binding_dir='/mnt/runtime/write/emulated/0/the_binding'

mkdir -p -v "$drive_mount_dir"
mount \
    -t ext4 \
    -o nosuid,nodev,noexec,noatime \
    "$ext4_blockdev_path" "$drive_mount_dir"

mkdir -p -v "$drive_mount_dir"/the_binding
chmod -R 777 "$drive_mount_dir"/the_binding
chown -R sdcard_rw:sdcard_rw "$drive_mount_dir"

# may be possible to avoid this by mounting to /mnt/expand/<uuid>
# TODO: use magiskpolicy https://github.com/topjohnwu/Magisk/blob/master/docs/tools.md#magiskpolicy
setenforce 0

mkdir -p -v "$internal_binding_dir"
mount \
    -t sdcardfs \
    -o nosuid,nodev,noexec,noatime,gid=9997 \
    "$drive_mount_dir/the_binding" "$internal_binding_dir"

# TODO: reduce permissions via chmod & sdcardfs mask

am broadcast \
  -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d file:///storage/emulated/0/the_binding/

echo "ext4 drive mounted successfully"
