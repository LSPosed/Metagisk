#####################################################################
#   Emulator Magisk in System Setup
#####################################################################
#
# Support API level: 23 - 35
#
# With an emulator booted and accessible via ADB, usage:
# ./build.py system
#
# This script will modify init.rc to install Magisk to the system
# partition.
# This is useful for setting up the emulator for testing modules,
# and developing root apps using some system writeable Android emulator
# instead of a real device.
#
# This only covers the "core" features of Magisk. For testing
# magiskinit, please checkout avd_patch.sh.
#
#####################################################################

if [ ! -f /system/build.prop ]; then
  # Running on PC
  echo "Please run \`./build.py emulator\` instead of directly executing the script!"
  exit 1
fi

cd /data/local/tmp || exit 1
chmod 755 busybox

if [ -z "$FIRST_STAGE" ]; then
  export FIRST_STAGE=1
  export ASH_STANDALONE=1
  if [ "$(./busybox id -u)" -ne 0 ]; then
    # Re-exec script with root
    exec /system/xbin/su 0 /data/local/tmp/busybox sh "$0"
  else
    # Re-exec script with busybox
    exec ./busybox sh "$0"
  fi
fi

pm install -r -g "$(pwd)"/magisk.apk

# Extract files from APK
unzip -oj magisk.apk 'assets/util_functions.sh'
. ./util_functions.sh

api_level_arch_detect
INSTALL_PATH=/system/xbin/magisk
rm -rf ${INSTALL_PATH:?}
mkdir -m 755 $INSTALL_PATH
unzip -oj magisk.apk "lib/$ABI/*" -x "lib/$ABI/libbusybox.so" -x "lib/$ABI/libinit-ld.so"
for file in lib*.so; do
  chmod 755 "$file"
  mv "$file" "$INSTALL_PATH/${file:3:${#file}-6}"
done

#if $IS64BIT && [ -e "/system/bin/linker" ]; then
#  unzip -oj magisk.apk "lib/$ABI32/libmagisk.so"
#  chmod 755 libmagisk.so
#  mv libmagisk.so $INSTALL_PATH/magisk32
#fi

# Magisk stuff
if [ ! -d /data/adb ]; then
    mkdir -m 700 /data/adb
    chcon u:object_r:adb_data_file:s0 /data/adb
fi
rm -rf "${MAGISKBIN:?}"
mkdir -m 755 "$MAGISKBIN"
for file in util_functions.sh boot_patch.sh; do
    [ -x "$MAGISKBIN/$file" ] || {
        unzip -d "$MAGISKBIN" -oj magisk.apk "assets/$file"
    }
done
mv magisk.apk $INSTALL_PATH/stub.apk
set_perm_recursive /system/xbin 0 2000 0755 0755

MAGISKTMP=/sbin
if ! mount | grep -q rootfs && [ ! -d /sbin ]; then
  # Android Q+ without sbin
  MAGISKTMP=/debug_ramdisk
fi

# SELinux stuffs
LIVECMD=""
if [ -d /sys/fs/selinux ]; then
  if [ -f /vendor/etc/selinux/precompiled_sepolicy ]; then
     LIVECMD="--load /vendor/etc/selinux/precompiled_sepolicy --live --magisk \$RULESCMD"
  elif [ -f /sepolicy ]; then
    LIVECMD="--load /sepolicy --live --magisk \$RULESCMD"
  else
    LIVECMD="--live --magisk \$RULESCMD"
  fi
fi

[ -f "$INSTALL_PATH/loadpolicy.sh" ] && rm -f "$INSTALL_PATH/loadpolicy.sh"
tee -a "$INSTALL_PATH/loadpolicy.sh" <<EOF >/dev/null || exit 1
#!/system/bin/sh
MAGISKTMP=$MAGISKTMP
export MAGISKTMP
MAKEDEV=1 $MAGISKTMP/magisk --preinit-device 2>&1
RULESCMD=""
RULEPATH="$MAGISKTMP/.magisk/preinit/sepolicy.rule"
[ -f "\$RULEPATH" ] && RULESCMD="--apply \$RULEPATH"
$MAGISKTMP/magiskpolicy $LIVECMD 2>&1
EOF
chmod 711 "$INSTALL_PATH/loadpolicy.sh"

if [ -f /system/etc/init/hw/init.rc.bak ]; then
  rm -f /system/etc/init/hw/init.rc
  mv /system/etc/init/hw/init.rc.bak /system/etc/init/hw/init.rc
  rm -f /system/etc/init/hw/init.rc.bak
fi

cp -af /system/etc/init/hw/init.rc /system/etc/init/hw/init.rc.bak
tee -a /system/etc/init/hw/init.rc <<EOF >/dev/null || exit 1
on post-fs-data
    mount tmpfs magisk $MAGISKTMP mode=0755
    copy $INSTALL_PATH/magisk $MAGISKTMP/magisk
    chmod 0755 $MAGISKTMP/magisk
    symlink ./magisk $MAGISKTMP/su
    symlink ./magisk $MAGISKTMP/resetprop
#    copy $INSTALL_PATH/magisk32 $MAGISKTMP/magisk32
#    chmod 0755 $MAGISKTMP/magisk32
    copy $INSTALL_PATH/magiskpolicy $MAGISKTMP/magiskpolicy
    chmod 0755 $MAGISKTMP/magiskpolicy
    symlink ./magiskpolicy $MAGISKTMP/supolicy
    mkdir $MAGISKTMP/.magisk 0711
    mkdir $MAGISKTMP/.magisk/device 0711
    mkdir $MAGISKTMP/.magisk/worker 0
    mount tmpfs magisk $MAGISKTMP/.magisk/worker mode=0755
    copy $INSTALL_PATH/stub.apk $MAGISKTMP/stub.apk
    chmod 0644 $MAGISKTMP/stub.apk
    exec u:r:su:s0 0 0 -- /system/bin/sh $INSTALL_PATH/loadpolicy.sh
    exec u:r:magisk:s0 0 0 -- $MAGISKTMP/magisk --post-fs-data

on property:vold.decrypt=trigger_restart_framework
    exec u:r:magisk:s0 0 0 -- $MAGISKTMP/magisk --service

on nonencrypted
    exec u:r:magisk:s0 0 0 -- $MAGISKTMP/magisk --service

on property:sys.boot_completed=1
    exec u:r:magisk:s0 0 0 --  $MAGISKTMP/magisk --boot-complete

on property:init.svc.zygote=stopped
    exec u:r:magisk:s0 0 0 -- $MAGISKTMP/magisk --zygote-restart
EOF

awk -e '{if($0 ~ /service zygote /){print $0;print "    exec u:r:magisk:s0 0 0 -- /debug_ramdisk/magisk --zygote-restart";a="";next}} 1' /system/etc/init/hw/init.rc >/system/etc/init/hw/init.rc.tmp \
  && mv /system/etc/init/hw/init.rc.tmp /system/etc/init/hw/init.rc

[ -f /system/etc/init/magisk.rc ] || {
  for i in /system/etc/init/hw/*; do
    if [[ "$i" =~ init.zygote.+\.rc ]]; then
      awk -e '{if($0 ~ /service zygote /){print $0;print "    exec u:r:magisk:s0 0 0 -- /debug_ramdisk/magisk --zygote-restart";a="";next}} 1' "$i">"$i".tmp && mv "$i".tmp "$i"
    fi
  done
}

cp -af ./busybox "$MAGISKBIN"/busybox
cd $INSTALL_PATH || exit 1
for file in magisk magiskpolicy magiskboot magiskinit stub.apk; do
    [ -x "$MAGISKBIN/$file" ] || {
        cp -af ./$file "$MAGISKBIN"/$file
    }
done
set_perm_recursive "$MAGISKBIN" 0 0 0755 0755
echo "#MAGISK">/system/etc/init/magisk.rc
