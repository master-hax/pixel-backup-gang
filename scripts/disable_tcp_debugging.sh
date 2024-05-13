#!/bin/sh -ex

################################################################################
# Description: disable adb access over tcp
# Author: Vivek Revankar <vivek@master-hax.com>
# Usage: ./disable_tcp_debugging.sh
################################################################################

setprop service.adb.tcp.port ""