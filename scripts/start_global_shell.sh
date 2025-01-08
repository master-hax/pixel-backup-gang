#!/bin/sh -e

################################################################################
# Description: start a shell in the global mount namespace
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./start_global_shell.sh
################################################################################

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  nsenter -t 1 -m -- "$SHELL" -c \
"
  cd $PWD \
  && echo 'entering global mount namespace 🌐' \
  && $SHELL \
  && echo 'exiting global mount namespace 👋' \
"
else
  echo 'already running in global mount namespace 🤔'
fi
