#!/bin/sh -ex

################################################################################
# Description: mounts the specified NFS export to /the_binding
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./mount_nfs.sh <SERVER> <EXPORT_PATH>
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo "not running in global mount namespace, try elevating first"
  exit 1
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <server> <export_path> e.g. $0 192.168.1.5 /export/mydrive" >&2
  exit 1
fi

nfs_server=$1
nfs_export_path=$2

case "$nfs_export_path" in
  /*) ;;
  *)
    echo "expected export_path to start with '/', got '$nfs_export_path'" >&2
    exit 1
    ;;
esac

nfs_export="$nfs_server:$nfs_export_path"

drive_mount_dir='/mnt/my_drive'
internal_binding_dir='/mnt/runtime/write/emulated/0/the_binding'

# patch the selinux policy to allow NFS mounting
magiskpolicy --live "allow kernel kernel capability net_raw"          # NFS/sunrpc socket setup
magiskpolicy --live "allow kernel kernel capability net_bind_service" # lockd's (unused) bind attempt
magiskpolicy --live "allow media_rw_data_file media_rw_data_file filesystem associate"

mkdir -p -v "$drive_mount_dir"
# addr=: toybox mount doesn't parse "server:" itself like nfs-utils' mount.nfs does
# nolock: no local rpcbind for lockd/NLM to register with, so it'd just fail
# nosharecache: forces a fresh superblock, else a cached one from an earlier
#   mount (different context=) causes EINVAL ("same superblock, different security settings")
# context=...media_rw_data_file...: NFS has no xattr support, so files would
#   default to "unlabeled" and fail SELinux's associate check on creation -
#   pin one real context for the whole mount instead of per-file labeling
mount \
    -t nfs \
    -o nosuid,nodev,noexec,noatime,vers=3,soft,timeo=100,retrans=3,addr="$nfs_server",nolock,nosharecache,context=u:object_r:media_rw_data_file:s0 \
    "$nfs_export" "$drive_mount_dir"

mkdir -p -v "$drive_mount_dir"/the_binding
# TODO: use sdcardfs's mask= mount option instead of chmod -R 777 here, so we
# don't have to recursively rewrite permissions on the actual NFS export
chmod -R 777 "$drive_mount_dir"/the_binding

mkdir -p -v "$internal_binding_dir"
mount \
    -t sdcardfs \
    -o nosuid,nodev,noexec,noatime,gid=9997 \
    "$drive_mount_dir/the_binding" "$internal_binding_dir"

am broadcast \
  -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d file:///storage/emulated/0/the_binding/

echo "NFS export mounted successfully"
