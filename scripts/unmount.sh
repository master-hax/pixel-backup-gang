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

umount -v /mnt/pass_through/0/emulated/0/the_binding
umount -v /mnt/runtime/write/emulated/0/the_binding
umount -v /mnt/my_drive
