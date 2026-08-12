:

# Set up locations

LOG=/data/local/tmp/cifs-mounter.txt
CIFS=/mnt/runtime/write/emulated/0/CIFS.mount
internal="/mnt/runtime/write/emulated/0/the_binding"
internalURI="file:///storage/emulated/0/the_binding"

# Short circuit exit if CIFS already mounted
#
already=`mount | grep "on $CIFS"`
if [ "$already" != "" ] ; then
  echo "CIFS ALREADY MOUNTED!" | tee $LOG
  exit
fi

echo "internal=$internal" | tee $LOG

SHARE=`grep ^SHARE /sdcard/CIFS | awk '{print $2}'`
USERNAME=`grep ^USERNAME /sdcard/CIFS | awk '{print $2}'`
PASSWORD=`grep ^PASSWORD /sdcard/CIFS | awk '{print $2}'`
if [ "$SHARE" == "" ] ; then
  echo "ERROR: Missing SHARE in /sdcard/CIFS" | tee -a $LOG
  exit
fi
if [ "$USERNAME" == "" ] ; then
  echo "ERROR: Missing USERNAME in /sdcard/CIFS" | tee -a $LOG
  exit
fi
if [ "$PASSWORD" == "" ] ; then
  echo "ERROR: Missing PASSWORD in /sdcard/CIFS" | tee -a $LOG
  exit
fi

# create CIFS mountpoint as needed and set up selinux policies
#
if [ ! -d $CIFS ] ; then
  mkdir $CIFS
  chgrp media_rw $CIFS
  chmod 750 $CIFS
fi
#magiskpolicy --live "allow kernel kernel capability net_raw"
#magiskpolicy --live "allow kernel kernel socket { create bind }"
#magiskpolicy --live "allow mediaprovider unlabeled dir getattr"
#magiskpolicy --live "allow platform_app unlabeled dir getattr"
setenforce 0

# mount that badboy
#
echo "mounting SHARE=$SHARE with USERNAME=$USERNAME and PASSWORD=<REDACT>" | tee -a $LOG
mount -t cifs -o username=$USERNAME,password=$PASSWORD,vers=2.1,ro,noatime,uid=0,gid=1015 $SHARE $CIFS

# detect mount point of mounted CIFS storage (should be $CIFS if it is really mounted)
#
external=`mount | grep "on $CIFS" | awk '{print $3}'` 

echo "external=$external" | tee -a $LOG

# Short circuit exit if there is no CIFS storage detected
#
if [ "$external" == "" ] ; then
  echo "NO MOUNTED CIFS STORAGE FOUND!" | tee -a $LOG
  exit
fi

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

# Perform the mount
#
mount -t sdcardfs -o nosuid,nodev,noexec,noatime,gid=9997 $external $internal
#mount -t sdcardfs -o nosuid,nodev,noexec,noatime,uid=0,gid=1015 $external $internal

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
