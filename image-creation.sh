#!/bin/bash

source base.conf
[ -f custom.conf ] && source custom.conf

#tmp variables
rootfs="work_dir/rootfs"

# variables
fstype="ext4"
root_uuid=$(cat </proc/sys/kernel/random/uuid | less)

#script
# Calculate the space to create the image.
root_size=$(du -s -B1 "${rootfs}" --exclude="${rootfs}"/boot | cut -f1)
root_extra=$((root_size * 5 * 1024 / 5 / 1024 / 1000))
raw_size=$(($((free_space * 1024)) + root_extra + $((bootsize * 1024)) + 4096))
img_size=$(echo "${raw_size}"Ki | numfmt --from=iec-i --to=si)
[ -d out_dir ] || mkdir -p "out_dir/"
fallocate -l "${img_size}" "out_dir/${image_name}.img"

# Create the disk partitions
parted -s "out_dir/${image_name}.img" mklabel msdos
parted -s "out_dir/${image_name}.img" mkpart primary fat32 1MiB "${bootsize}"MiB
parted -s -a minimal "out_dir/${image_name}.img" mkpart primary "$fstype" "${bootsize}"MiB 100%

# Set partitions variables
img="out_dir/${image_name}.img"
num_parts=$(fdisk -l $img | grep "${img}[1-2]" | wc -l)
if [ "$num_parts" = "2" ]; then
	extra=1
    part_type1=$(fdisk  -l $img | grep ${img}1 | awk '{print $6}')
    part_type2=$(fdisk  -l $img | grep ${img}2 | awk '{print $6}')
    if [[ "$part_type1" == "c" ]]; then
      bootfstype="vfat"
    elif [[ "$part_type1" == "83" ]]; then
      bootfstype=${bootfstype:-"$fstype"}
    fi
    rootfstype=${rootfstype:-"$fstype"}
    loopdevice=$(losetup --show -fP "$img")
    bootp="${loopdevice}p1"
    rootp="${loopdevice}p2"
elif [ "$num_parts" = "1" ]; then
	part_type1=$(fdisk  -l $img | grep ${img}1 | awk '{print $6}')
    if [[ "$part_type1" == "83" ]]; then
      rootfstype=${rootfstype:-"$fstype"}
    fi
    rootfstype=${rootfstype:-"$fstype"}
    loopdevice=$(losetup --show -fP "$img")
	rootp="${loopdevice}p1"
fi

# Formatting boot partition.
if [ -n "${bootp}" ] ; then
	case $bootfstype  in
      vfat) mkfs.vfat -n BOOT -F 32 "${bootp}" ;;
      ext4) features="^64bit,^metadata_csum"
      mkfs -O "$features" -t "$fstype" -L BOOT "${bootp}" ;;
      ext2 | ext3) features="^64bit"
      mkfs -O "$features" -t "$fstype" -L BOOT "${bootp}" ;;
    esac
    bootfstype=$(blkid -o value -s TYPE $bootp)
  fi
# Formatting root partition.
if [ -n "${rootp}" ] ; then
	case $rootfstype  in
      ext4) features="^64bit,^metadata_csum" ;;
      ext2 | ext3) features="^64bit" ;;
    esac
    yes | mkfs -U "$root_uuid" -O "$features" -t "$fstype" -L ROOTFS "${rootp}"
    root_partuuid=$(blkid -s PARTUUID -o value ${rootp})
    rootfstype=$(blkid -o value -s TYPE $rootp)
fi

# Create the dirs for the partitions and mount them
mount_dir="work_dir/mount"
mkdir -p "${mount_dir}"/root/
mount "${rootp}" "${mount_dir}"/root
mkdir -p "${mount_dir}"/root/boot
mount "${bootp}" "${mount_dir}"/root/boot

rsync -HPavz -q --exclude boot "${rootfs}"/ "${mount_dir}"/root/
sync
rsync -rtx -q "${rootfs}"/boot "${mount_dir}"/root
sync
