:

LOG=/data/local/tmp/usb-mounter.txt
internal="/mnt/runtime/write/emulated/0/DCIM/Camera/sidemount"
echo "internal=$internal" | tee $LOG

if [ ! -d $internal ] ; then
  mkdir $internal
fi

already=`mount | grep $internal`
if [ "$already" != "" ] ; then
  echo "ALREADY MOUNTED!" | tee -a $LOG
  exit
fi

external=`mount | grep "on /mnt/media_rw/" | awk '{print $3}'` 
echo "external=$external" | tee -a $LOG
if [ "$external" == "" ] ; then
  echo "NO EXTERNAL STORAGE FOUND!" | tee -a $LOG
  exit
fi

mount -t sdcardfs -o nosuid,nodev,noexec,noatime,gid=9997 $external $internal
mount | grep $external | tee -a $LOG

already=`mount | grep $internal`
if [ "$already" != "" ] ; then
  echo "mount SUCCESS!" | tee -a $LOG
else
  echo "mount FAIL!" | tee -a $LOG
fi
