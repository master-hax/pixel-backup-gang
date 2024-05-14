#!/bin/sh -ex

################################################################################
# Description: enable adb access over tcp on the specified port
# Author: Vivek Revankar <vivek@master-hax.com>
# Usage: ./enable_tcp_debugging.sh <PORT>
################################################################################

setprop service.adb.tcp.port $1
