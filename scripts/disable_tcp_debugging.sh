#!/bin/sh -ex

################################################################################
# Description: disable adb access over tcp
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./disable_tcp_debugging.sh
################################################################################

setprop service.adb.tcp.port ""

# TODO: stop adb service
