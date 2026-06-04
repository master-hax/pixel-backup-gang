:

# set up for adb over tcp
#
setprop service.adb.tcp.port 5555
killall adbd
sleep 3

# 
# Diagnostic finish
#
netstat -a | grep 5555
theip=`ip addr | grep "inet " | grep brd | sed 's-/- -' | awk '{print $2}'`
echo ""
echo "IP address is $theip.  To connect use"
echo " adb connect $theip:5555"
