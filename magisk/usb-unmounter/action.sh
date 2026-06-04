:

LOG=/data/local/tmp/usb-unmounter.txt
internal="/mnt/runtime/write/emulated/0/DCIM/Camera/sidemount"
echo "internal=$internal" | tee $LOG

already=`mount | grep $internal`
if [ "$already" == "" ] ; then
  echo "NOT MOUNTED!" | tee -a $LOG
  exit
fi

umount $internal
already=`mount | grep $internal`
if [ "$already" == "" ] ; then
  echo "unmount SUCCESS!" | tee -a $LOG
fi
