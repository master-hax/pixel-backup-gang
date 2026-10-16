:

# Set up locations

LOG=/data/local/tmp/usb-unmounter.txt
internal="/mnt/runtime/write/emulated/0/the_binding"
echo "internal=$internal" | tee $LOG

# Short circuit exit if already unmounted
#
already=`mount | grep $internal`
if [ "$already" == "" ] ; then
  echo "NOT MOUNTED!" | tee -a $LOG
  exit
fi

# Perform unmount
#
umount $internal

# Sanity Check
#
already=`mount | grep $internal`
if [ "$already" == "" ] ; then
  echo "unmount SUCCESS!" | tee -a $LOG
fi
