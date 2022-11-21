#! /bin/sh

# This is an example installer script. For OS-Installer to use it, place it at:
# /etc/os-installer/scripts/install.sh
# The script gets called with the following environment variables set:
# OSI_LOCALE              : Locale to be used in the new system
# OSI_DEVICE_PATH         : Device path at which to install
# OSI_DEVICE_IS_PARTITION : 1 if the specified device is a partition (0 -> disk)
# OSI_DEVICE_EFI_PARTITION: Set if device is partition and system uses EFI boot.
# OSI_USE_ENCRYPTION      : 1 if the installation is to be encrypted
# OSI_ENCRYPTION_PIN      : The encryption pin to use (if encryption is set)

# sanity check that all variables were set
if [ -z ${OSI_LOCALE+x} ] || \
   [ -z ${OSI_DEVICE_PATH+x} ] || \
   [ -z ${OSI_DEVICE_IS_PARTITION+x} ] || \
   [ -z ${OSI_DEVICE_EFI_PARTITION+x} ] || \
   [ -z ${OSI_USE_ENCRYPTION+x} ] || \
   [ -z ${OSI_ENCRYPTION_PIN+x} ]
then
    echo "Installer script called without all environment variables set!"
    exit 1
fi


echo "Installation started!"

echo "Partitionning the system..."

# Je ne sais pas vraiment ce que je fais là
if [[ $OSI_DEVICE_IS_PARTITION == 1 ]]; then
   mkfs.ext4 $OSI_DEVICE_PATH 
   if [[ -v $OSI_DEVICE_EFI_PARTITION ]]; then
      mkfs.fat -F 32 
   fi

else
   echo "banane"
fi

echo "Done"

mount #PARTITION_ROOT# /mnt

export LFS="/mnt"
cd $LFS

echo "Creating the distro structure..."
# Create the distro structure
touch $LFS/INDEX

mkdir -p $LFS/dev/pts
mkdir -p $LFS/proc
mkdir -p $LFS/sys
mkdir -p $LFS/run
mkdir -p $LFS/tmp
mkdir -p $LFS/etc
mkdir -p $LFS/var
mkdir -p $LFS/usr/bin
mkdir -p $LFS/usr/sbin
mkdir -p $LFS/usr/lib
mkdir -p $LFS/usr/share
mkdir -p $LFS/usr/include
mkdir -p $LFS/usr/libexec
mkdir -p $LFS/boot

ln -s usr/bin $LFS/bin
ln -s usr/lib $LFS/lib
ln -s usr/sbin $LFS/sbin
ln -s usr/lib $LFS/lib64
ln -s lib $LFS/usr/lib64

echo "Done"

echo "Creating the DNS configuration..."
# Create the DNS configuration
echo "nameserver 8.8.8.8" > $LFS/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $LFS/etc/resolv.conf
echo "Done"

echo "Installing a basic system to chroot into..."
ROOT=$LFS squirrel get binutils linux-api-headers glibc gcc-lib-c++ m4 ncurses bash coreutils diffutils file findutils gawk grep gzip sed tar xz gettext perl python3 texinfo util-linux squirrel --chroot=$LFS -y 
echo "Done"

echo
echo "Installing the system, it can take a while !"
echo

echo "Mount temporary filesystems..."
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount --rbind /sys $LFS/sys
mount --make-rslave $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
echo "Done"

echo "Configuring squirrel..."
echo "main http://stocklinux.hopto.org:8080/45w22/main" > $LFS/etc/squirrel/branches
echo "gui http://stocklinux.hopto.org:8080/45w22/gui" >> $LFS/etc/squirrel/branches
echo "extra http://stocklinux.hopto.org:8080/45w22/extra" >> $LFS/etc/squirrel/branches
echo "cli http://stocklinux.hopto.org:8080/45w22/cli" >> $LFS/etc/squirrel/branches
echo "Done"

echo
echo 'Installation completed.'

exit 0
