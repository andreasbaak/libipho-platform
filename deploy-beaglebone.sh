#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <sd-card-drive>"
  echo "Example: $0 /dev/sdb"
  exit 1
fi

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DEVICE=$1
if [ ! -b ${DEVICE} ]; then
  echo "Device ${DEVICE} is not a block device!"
  exit 1
fi

BASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IMGDIR=${BASE_PATH}/deploy/images/beaglebone

MOUNT_ERROR() {
  echo "Could not detect the directory in which the $1 partition is mounted."
  echo "Did you format the sd-card with the 'format_sd_card.sh' script"
  echo "and did you mount the sd-card afterwards?"
  exit 1
}

DIR_ERROR() {
  echo "Expected $1 to be a directory. However, it does not appear to be the case!"
  exit 1
}

BOOTDIR=`mount | grep ${DEVICE} | grep boot | awk '{print $3}'`
ROOTDIR=`mount | grep ${DEVICE} | grep rootfs | awk '{print $3}'`

if [ "x${BOOTDIR}" = "x" ]; then
  MOUNT_ERROR boot
fi
if [ "x${ROOTDIR}" = "x" ]; then
  MOUNT_ERROR rootfs
fi

if [ ! -d "${BOOTDIR}" ]; then
  DIR_ERROR ${ROOTDIR}
fi
if [ ! -d "${BOOTDIR}" ]; then
  DIR_ERROR ${ROOTDIR}
fi

set -e
echo "Preparing boot partition in $BOOTDIR"
cp $IMGDIR/MLO-beaglebone $BOOTDIR/MLO
cp $IMGDIR/u-boot-beaglebone.img $BOOTDIR/u-boot.img

echo "Preparing root partition in $ROOTDIR"
tar x -C $ROOTDIR -f $IMGDIR/libipho-image-beaglebone.tar.bz2
tar x -C $ROOTDIR -f $IMGDIR/modules-beaglebone.tgz
cp $IMGDIR/zImage-beaglebone.bin $ROOTDIR/zImage

cp $IMGDIR/zImage-am335x-bone.dtb $ROOTDIR/boot/am335x-bone.dtb
cp $IMGDIR/zImage-am335x-boneblack.dtb $ROOTDIR/boot/am335x-boneblack.dtb

echo "Unmounting partitions"
umount $BOOTDIR
umount $ROOTDIR
echo "Done. Everything is deployed. You should be able to boot your device from the sd-card."
