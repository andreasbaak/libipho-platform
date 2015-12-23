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

# The SD-card needs to partitions: one boot and one root partition.
DRIVE=$1
PARTITION1=${DRIVE}1
PARTITION2=${DRIVE}2

# Make sure that the partitions are not mounted.
umount ${PARTITION1}
umount ${PARTITION2}

SIZE=$(fdisk -l ${DRIVE} | grep Disk | grep bytes | awk '{print $5}')
echo "Size of the sd-card: - ${SIZE} bytes"

CYLINDERS=$(echo ${SIZE}/255/63/512 | bc)
echo "Cylinders in the sd-card: ${CYLINDERS}"

echo "Partitioning ${DRIVE}..."
{
echo ,70,C,*
echo ,,L,-
} | sfdisk --no-reread -f -u M -D -H 255 -S 63 -C ${CYLINDERS} ${DRIVE}

echo "Formatting ${DRIVE}..."

# Partition 1 (boot): FAT32
# Partition 2 (root): EXT4
# Check wheter PARTITION1 is a block device
if [ -b ${PARTITION1} ]; then
  mkfs.vfat -F 32 -n "boot" ${PARTITION1}
else
  echo "Device ${PARTITION1} is not a block device!"
fi

if [ -b ${PARITION2} ]; then
  mkfs.ext4 -L "rootfs" ${PARTITION2}
else
  echo "Device ${PARTITION1} is not a block device!"
fi

sync

sfdisk --re-read ${DRIVE}

