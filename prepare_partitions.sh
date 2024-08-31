#!/bin/sh

die() {
        echo "$*"
        exit 1
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-d|--device)
			DEVICE="$2"
                        shift
                        shift
		;;
		-r|--root-size)
			RSIZE="$2"
                        shift
                        shift
		;;
		-s|--swap-size)
			SSIZE="$2"
                        shift
                        shift
		;;
		-*|--)
                        die "Unknown option"
		;;
                *)
                        die "Unknown argument"
	esac
done

[ -z "$DEVICE" ] && die "Provide the device"
[ -z "$RSIZE" ] && die "Provide the size of the root partition"
[ -z "$SSIZE" ] && die "Provide the size of the swap partition"

echo "Running the script with the following options:"
echo -e "\tDevice: $DEVICE\tRoot size: $RSIZE""GB\t Swap size: $SSIZE""GB"

parted "$DEVICE" -- mklabel gpt &&\
        parted "$DEVICE" -- mkpart root ext4 512MB -"$RSIZE"GB &&\
        parted "$DEVICE" -- mkpart swap linux-swap -"$SSIZE"GB 100% &&\
        parted "$DEVICE" -- mkpart ESP fat32 1MB 512MB &&\
        parted "$DEVICE" -- set 3 esp on  || die "Unable to create partition table"

mkfs.ext4 -L nixos "$DEVICE"1 &&\
        mkswap -L swap "$DEVICE"2 &&\
        mkfs.fat -F 32 -n boot "$DEVICE"3 || die "Unable to create filesystems"

mount /dev/disk/by-label/nixos /mnt || die "Unable to mount root partition"
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot || die "Unable to mount boot partition"

swapon "$DEVICE"2 || die "Unable to activate the swap"

echo "The partitions for device $DEVICE are ready for OS installation"
