#!/bin/sh -e

################################################################################
# Description: enters the termux environment from an adb shell
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./run_as_termux.sh
################################################################################

if [ "$#" -ne 0 ]; then
  echo "Usage: $0" >&2
  exit 1
fi

run-as com.termux files/usr/bin/bash -c \
"export PATH=/data/data/com.termux/files/usr/bin:$PATH \
&& export LD_PRELOAD=/data/data/com.termux/files/usr/lib/libtermux-exec.so \
&& echo 'running as termux' \\
&& bash -i"