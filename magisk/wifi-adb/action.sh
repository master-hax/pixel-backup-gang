:

setprop service.adb.tcp.port 5555
killall adbd
sleep 3
ip addr | grep inet
netstat -a | grep 5555
