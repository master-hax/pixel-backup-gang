#!/bin/sh -e

################################################################################
# Description: find the path of the block device with the specified UUID
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./find_device.sh <UUID_FILE_PATH>
################################################################################

# TODO: show a "not found" message

blkid -t UUID="$(cat "$1")" | awk -v col=1 '{print $col}' | sed 's/.$//'
