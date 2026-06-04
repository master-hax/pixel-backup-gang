:

# Set up locations

LOG=/data/local/tmp/usb-mounter.txt
internal="/mnt/runtime/write/emulated/0/the_binding"
internalURI="file:///storage/emulated/0/the_binding"

# detect mount point of mounted USB storage
#
external=`mount | grep "on /mnt/media_rw/" | awk '{print $3}'` 

echo "internal=$internal" | tee $LOG
echo "external=$external" | tee -a $LOG

# Make internal mount point as needed
#
if [ ! -d $internal ] ; then
  mkdir $internal
fi

# Short circuit exit if already mounted at internal mount point
#
already=`mount | grep $internal`
if [ "$already" != "" ] ; then
  echo "ALREADY MOUNTED!" | tee -a $LOG
  exit
fi

# Short circuit exit if there is no USB storage detected
#
if [ "$external" == "" ] ; then
  echo "NO EXTERNAL STORAGE FOUND!" | tee -a $LOG
  exit
fi

# Perform the mount
#
mount -t sdcardfs -o nosuid,nodev,noexec,noatime,gid=9997 $external $internal

# Sanity check
#
mount | grep $external | tee -a $LOG
already=`mount | grep $internal`
if [ "$already" != "" ] ; then
  echo "mount SUCCESS!" | tee -a $LOG
  #
  # If successful broadcast media scanner intent
  #
  am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d $internalURI
else
  echo "mount FAIL!" | tee -a $LOG
fi
