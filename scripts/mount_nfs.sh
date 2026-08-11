#!/bin/sh
set -e

################################################################################
# Description: mounts the specified NFS export to /the_binding
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./mount_nfs.sh <SERVER> <EXPORT_PATH>
#
# also used, unmodified, by the Magisk auto-mount module (see default.nix's
# mkNfsAutoMountMagiskModule) - `set -e` is explicit rather than a shebang
# flag so behavior is identical whether this runs directly or via `sh
# mount_nfs.sh ...`, and log() is used throughout so both contexts share the
# same "pbg: " tag for `dmesg`/terminal grepping. no `-x`: log() already
# covers every meaningful step, and its command-echo trace is just noise in
# dmesg when run via the module. every log() call is explicitly leveled:
# info (normal progress), warning (tolerable, script continues), error
# (script exits nonzero)
################################################################################

log() { echo "pbg: mount_nfs.sh: $*"; }

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  log "error: not running in global mount namespace, try elevating first"
  exit 1
fi

if [ "$#" -ne 2 ]; then
  log "error: usage: $0 <server> <export_path> e.g. $0 192.168.1.5 /export/mydrive"
  exit 1
fi

nfs_server=$1
nfs_export_path=$2

case "$nfs_export_path" in
  /*) ;;
  *)
    log "error: expected export_path to start with '/', got '$nfs_export_path'"
    exit 1
    ;;
esac

nfs_export="$nfs_server:$nfs_export_path"

drive_mount_dir='/mnt/my_drive'
internal_binding_dir='/mnt/runtime/write/emulated/0/the_binding'

log "info: mounting $nfs_export"

# best-effort: unmount any previous attempt first, so this script is safe to
# re-run. not guaranteed - if something's still using a mount, this fails
# silently and the mount below will just stack on top of the stale one
log "info: unmounting any previous attempt (best-effort)"
umount "$internal_binding_dir" 2>/dev/null || true
umount "$drive_mount_dir" 2>/dev/null || true

# patch the selinux policy to allow NFS mounting - not fatal if any of these
# fail (e.g. already applied from a previous run)
log "info: patching selinux policy"
magiskpolicy --live "allow kernel kernel capability net_raw" \
  || log "warning: magiskpolicy net_raw rule failed (already applied? not fatal)"          # NFS/sunrpc socket setup
magiskpolicy --live "allow kernel kernel capability net_bind_service" \
  || log "warning: magiskpolicy net_bind_service rule failed (already applied? not fatal)" # lockd's (unused) bind attempt
magiskpolicy --live "allow media_rw_data_file media_rw_data_file filesystem associate" \
  || log "warning: magiskpolicy associate rule failed (already applied? not fatal)"

log "info: mounting nfs export to $drive_mount_dir"
mkdir -p -v "$drive_mount_dir" \
  || { log "error: mkdir $drive_mount_dir failed (exit $?)"; exit 1; }
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
    "$nfs_export" "$drive_mount_dir" \
  || { log "error: nfs mount failed (exit $?) - is the server reachable & export path correct?"; exit 1; }

mkdir -p -v "$drive_mount_dir"/the_binding \
  || { log "error: mkdir $drive_mount_dir/the_binding failed (exit $?)"; exit 1; }
# TODO: use sdcardfs's mask= mount option instead of chmod -R 777 here, so we
# don't have to recursively rewrite permissions on the actual NFS export.
# not fatal: pre-existing files owned by a different NFS-squashed uid can't
# be chmod'd (EPERM) even though the mount itself is fine
log "info: relaxing permissions on the_binding"
chmod -R 777 "$drive_mount_dir"/the_binding \
  || log "warning: chmod -R 777 failed on some files (owned by a different NFS uid?), continuing anyway"

log "info: binding the_binding into internal storage at $internal_binding_dir"
mkdir -p -v "$internal_binding_dir" \
  || { log "error: mkdir $internal_binding_dir failed (exit $?)"; exit 1; }
mount \
    -t sdcardfs \
    -o nosuid,nodev,noexec,noatime,gid=9997 \
    "$drive_mount_dir/the_binding" "$internal_binding_dir" \
  || { log "error: sdcardfs bind mount failed (exit $?)"; exit 1; }

log "info: NFS export mounted successfully, triggering media scan"
if am broadcast \
    -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
    -d file:///storage/emulated/0/the_binding/; then
  log "info: media scan broadcast completed"
else
  log "warning: media scan broadcast failed (exit $?), not fatal"
fi
