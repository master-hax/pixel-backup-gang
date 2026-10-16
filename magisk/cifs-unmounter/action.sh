:

# Set up locations

LOG=/data/local/tmp/cifs-unmounter.txt
internal="/mnt/runtime/write/emulated/0/the_binding"
#CIFS=/data/media/0/CIFS.mount
CIFS=/mnt/runtime/write/emulated/0/CIFS.mount

# Short circuit exit if CIFS not mounted
#
already=`mount | grep "on $CIFS"`
if [ "$already" == "" ] ; then
  echo "CIFS NOT MOUNTED!" | tee $LOG
  exit
fi

echo "internal=$internal" | tee $LOG

# Short circuit exit if already unmounted
#
already=`mount | grep $internal`
if [ "$already" == "" ] ; then
  echo "ERROR: CIFS mounted but not NOT cross mounted!... attempting unmount CIFS" | tee -a $LOG
  umount $CIFS
  already=`mount | grep "on $CIFS"`
  if [ "$already" == "" ] ; then
    echo "unmount CIFS SUCCESS!" | tee -a $LOG
  else
    echo "unmount CIFS FAIL!" | tee -a $LOG
  fi
  exit
fi

# Perform unmounts
#
echo "unmounting crossmount" | tee -a $LOG
umount $internal
# Sanity Check
#
already=`mount | grep $internal`
if [ "$already" == "" ] ; then
  echo "unmount crossmount SUCCESS!" | tee -a $LOG
else
  echo "unmount crossmount FAIL!" | tee -a $LOG
fi

echo "unmounting CIFS" | tee -a $LOG
umount $CIFS

already=`mount | grep "on $CIFS"`
if [ "$already" == "" ] ; then
  echo "unmount CIFS SUCCESS!" | tee -a $LOG
else
  echo "unmount CIFS FAIL!" | tee -a $LOG
fi
