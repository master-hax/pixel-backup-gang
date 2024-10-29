#!/bin/sh -ex

################################################################################
# Description: bind mounts the specified directory to /the_binding in internal storage
# Author: Vivek Revankar <vivek@master-hax.com>
# Usage: ./mount_folder.sh <DIRECTORY_PATH>
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo "not running in global mount namespace, try elevating first"
  exit 1
fi

mount -t sdcardfs -o nosuid,nodev,noexec,noatime,gid=9997 "$1" /mnt/runtime/write/emulated/0/the_binding
