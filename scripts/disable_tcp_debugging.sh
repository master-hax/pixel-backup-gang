#!/bin/sh -e

################################################################################
# Description: disable adb access over tcp
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./disable_tcp_debugging.sh
################################################################################

setprop service.adb.tcp.port "" && stop adbd && echo "adbd service stopped & no longer listening"
