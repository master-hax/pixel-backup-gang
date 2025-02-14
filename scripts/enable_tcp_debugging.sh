#!/bin/sh -e

################################################################################
# Description: enable adb access over tcp on the specified port
# Contributors: Vivek Revankar <vivek@master-hax.com>
# Usage: ./enable_tcp_debugging.sh <PORT>
################################################################################

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <PORT_NUMBER>" >&2
  exit 1
fi

adb_port=$1

if (echo "$adb_port" | grep -E '^[0-9]+\n$' > /dev/null); then
  echo "invalid port $adb_port, port must be a positive integer <= 65535"
  exit 1
fi
    

if [ "$adb_port" -le 0 ] || [ "$adb_port" -ge 65536 ]; then
  echo "port must be > 0 and < 65536"
  exit 1
fi

setprop service.adb.tcp.port "$adb_port" && stop adbd && start adbd

echo "adbd now listening on tcp port $adb_port"