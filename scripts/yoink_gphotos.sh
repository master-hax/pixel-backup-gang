#!/bin/sh -ex

################################################################################
# Description: bind mounts a fresh google photos data directory on the external
#               drive over the real one, so it runs off the drive instead of
#               wearing out internal NAND
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./yoink_gphotos.sh
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo "not running in global mount namespace, try elevating first"
  exit 1
fi

package_name='com.google.android.apps.photos'
data_dir="/data/data/$package_name"
drive_mount_dir='/mnt/my_drive'
relocated_dir="$drive_mount_dir/yoinked_gphotos"

if ! mount | grep -q " $drive_mount_dir "; then
  echo "$drive_mount_dir is not mounted, run mount_ext4.sh first"
  exit 1
fi

if [ -e "$relocated_dir" ] && [ "$(stat -c '%d:%i' "$data_dir")" = "$(stat -c '%d:%i' "$relocated_dir")" ]; then
  echo "$data_dir is already bind mounted from $relocated_dir - nothing to do"
  exit 1
fi

am force-stop "$package_name"

[ -e "$relocated_dir" ] || mkdir "$relocated_dir"

owner=$(stat -c '%U:%G' "$data_dir")
# shellcheck disable=SC2012 # ls -Z is used for its selinux context column, not filename parsing - stat -c %C isn't supported on-device
context=$(ls -Zd "$data_dir" | awk '{print $1}')

chmod 700 "$relocated_dir"
chown -R "$owner" "$relocated_dir"
chcon -R "$context" "$relocated_dir"

mount -o bind "$relocated_dir" "$data_dir"

# mount_ext4.sh mounts the drive noexec, but google photos executes compiled
# code out of its code_cache directory - loosen just this bind mount to allow it
mount -o remount,bind,exec,nosuid,nodev "$data_dir"

am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p "$package_name"

echo "$package_name is now running off a separate instance on the external drive"
