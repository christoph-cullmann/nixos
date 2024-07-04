#
# kill old efi boot stuff
#

efibootmgr
efibootmgr -b 0 -B
efibootmgr -b 1 -B
efibootmgr -b 2 -B
efibootmgr -b 3 -B
efibootmgr -b 4 -B
efibootmgr

#
# install script below
#

# Defining some helper variables (these will be used in later code
# blocks as well, so make sure to use the same terminal session or
# redefine them later)
DISK=/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HBLR-000L2_S4DZNX0R362286
HOST=beta

# ensure 4k sector size
nvme format --lbaf=1 --force $DISK
nvme id-ns -H $DISK

sleep 5

# kill old data
sgdisk --zap-all $DISK
blkdiscard -v $DISK
wipefs -a $DISK
gdisk -l $DISK

# create partitions
parted $DISK -- mklabel gpt
sgdisk -n 1:0:+1024M -c 1:"EFI System Partition" -t 1:EF00 $DISK
sgdisk -n 2:0:0 -c 2:"Linux" -t 2:8e00 $DISK
parted $DISK -- set 1 boot on

sleep 5

# take a look
cat /proc/partitions

# boot partition
mkfs.fat -F 32 -n EFIBOOT $DISK-part1

sleep 5

# ZFS zpool creation with encryption
zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O atime=off \
    -O canmount=off \
    -O compression=on \
    -O dnodesize=auto \
    -O normalization=formD \
    -O xattr=sa \
    -O mountpoint=none \
    -O encryption=on \
    -O keylocation=prompt \
    -O keyformat=passphrase \
    zpool $DISK-part2

sleep 5

# create all the volumes
zfs create -o mountpoint=legacy zpool/data
zfs create -o mountpoint=legacy zpool/nix

sleep 5

# prepare install, tmpfs root
mount -t tmpfs none /mnt

# Create directories to mount file systems on
mkdir -p /mnt/{data,nix,home,boot,root,etc/nixos}

# mount the ESP
mount $DISK-part1 /mnt/boot

# mount volumes
mount -t zfs zpool/data /mnt/data
mount -t zfs zpool/nix /mnt/nix

# bind mount persistent stuff to data
mkdir -p /mnt/{data/home,data/root,data/nixos/$HOST}
mount --bind /mnt/data/home /mnt/home
mount --bind /mnt/data/root /mnt/root
mount --bind /mnt/data/nixos/$HOST /mnt/etc/nixos

# create fake /data to have the right paths
mkdir -p /data
mount --bind /mnt/data /data

# take a look
mount

# configure
nixos-generate-config --root /mnt
