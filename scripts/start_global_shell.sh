#!/bin/sh -e

################################################################################
# Description: start a shell in the global mount namespace
# Author: Vivek Revankar <vivek@master-hax.com>
# Usage: ./start_global_shell.sh
################################################################################

# TODO: return to current directory
# TODO: display success message

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  nsenter -t 1 -m -- /bin/sh
else
  echo 'already running in global mount namespace'
fi
