#!/bin/sh -ex

################################################################################
# Description: enable adb access over tcp on the specified port
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./enable_tcp_debugging.sh <PORT>
################################################################################

# TODO: verify port argument

setprop service.adb.tcp.port "$1"

# TODO: stop & restart adb service
