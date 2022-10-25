#===================================================================================
#
# FILE : install.sh
#
# USAGE : su -
#         ./install.sh
#
# DESCRIPTION : Install script for Stock Linux
#
# BUGS : ---
# NOTES : ---
# CONTRUBUTORS : Skythrew, Babilinx
# CREATED : october 2022
# REVISION: 25 october 2022
#
# LICENCE :
# Copyright (C) 2022 Skythrew, Babilinx
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with
# this program. If not, see https://www.gnu.org/licenses/.
#===================================================================================
COLOR_YELLOW=$'\033[0;33m'
COLOR_GREEN=$'\033[0;32m'
COLOR_RED=$'\033[0;31m'
COLOR_LIGHTBLUE=$'\033[1;34m'
COLOR_WHITE=$'\033[1;37m'
COLOR_LIGHTGREY=$'\e[37m'
COLOR_RESET=$'\033[0m'
C_RESET=$'\e[0m'

echo "Welcome into the installation script of Stock Linux"
echo """${COLOR_YELLOW}Dragons ahead !
This script is still in developpement, use it with precautions !
We are not responsable for enything that can appears pending the installation (data loss, break computer, burning house, WWIII, etc)${COLOR_RESET}"""

echo "Installing squirrel on the host system..."
git clone --branch 1.0.2-dev https://github.com/stock-linux/squirrel.git
ln -s $PWD/squirrel/squirrel /bin/squirrel

echo -e "#!/bin/sh\npython3 $PWD/squirrel/main.py \$@" > squirrel/squirrel
pip3 install docopt pyaml requests

mkdir -p $PWD/squirrel/dev/etc/squirrel/ $PWD/squirrel/dev/var/squirrel/repos/dist/ $PWD/squirrel/dev/var/squirrel/repos/local/ $PWD/squirrel/dev/var/squirrel/repos/local/main/

echo "configPath = '$PWD/squirrel/dev/etc/squirrel/'" > squirrel/utils/config.py
echo "distPath = '$PWD/squirrel/dev/var/squirrel/repos/dist/'" >> squirrel/utils/config.py
echo "localPath = '$PWD/squirrel/dev/var/squirrel/repos/local/'" >> squirrel/utils/config.py
echo "main http://stocklinux.hopto.org:8080/main/main" > squirrel/dev/etc/squirrel/branches
touch $PWD/squirrel/dev/var/squirrel/repos/local/main/INDEX

echo "Everything is configured !"

fdisk -l

read -p "On wich disk do you want to install the OS ? (ex: sda) " DISK_TO_INSTALL

echo "Stock Linux will be installed in $DISK_TO_INTALL. Ctrl+C to quit."
cfdisk /dev/$DISK_TO_INSTALL
read -p "What is the name of the root partition ? (ex: sda2) " ROOT_PARTITION
read -p "What is the name of the EFI partition ? (ex: sda1) " UEFI_PARTITION
mount /dev/$ROOT_PARTITION /mnt

export LFS="/mnt"
cd $LFS

touch $LFS/INDEX

echo "Installing a basic system to chroot into..."
ROOT=$LFS squirrel get binutils linux-api-headers glibc gcc-lib-c++ m4 ncurses bash coreutils diffutils file findutils gawk grep gzip sed tar xz gettext perl python3 texinfo util-linux --chroot=$LFS -y 

echo "Installing the system, it can take a while !"

mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount --rbind /sys $LFS/sys
mount --make-rslave /sys $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

cat << EOF | chroot $LFS /bin/sh
mkdir -p /var/squirrel/repos/{local,dist}
squirrel get man-pages iana-etc glibc zlib bzip2 xz zstd file readline m4 bc flex tcl expect dejagnu binutils libgmp libmpfr libmpc attr acl libcap shadow ncurses sed psmisc gettext grep bash libtool gdbm gperf expat inetutils less perl xmlparser intltool openssl kmod libelf python3 wheel coreutils check diffutils gawk findutils groff gzip iproute2 kbd libpipeline tar texinfo vim markupsafe jinja2 systemd dbus man-db procps util-linux e2fsprogs tzdata linux dhcpcd dracut wpasupplicant grub -y
pwconv
grpconv
read -p "What is the name of the user ? " USERNAME
useradd -m -G users,wheel,audio,video,sudo -s /bin/bash "$USERNAME"    # Admin access user
passwd "$USERNAME"
echo "Set the root password !"
passwd root
cd /boot
dracut
mount /dev/$UEFI_PARTITION /mnt
grub-install --target=x86_64-efi --efi-directory=/mnt
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# ls /usr/share/zoneinfo/
TZ_CONTINENT=Europe
TZ_CITY=Paris
ln -s /usr/share/zoneinfo/$TZ_CONTINENT/$TZ_CITY $LFS/etc/localtime

read -p "What keymap do you want to use ? (ex: fr, us, etc)" KEYMAP

cat > $LFS/etc/vconsole.conf << "EOF"
KEYMAP=$KEYMAP
FONT=Lat2-Terminus16
EOF

read -p "What lang do you want to use ? (ex: fr_FR.UTF-8, en_GB.ISO-8859-1, etc)" LANG
cat > $LFS/etc/locale.conf << "EOF"
LANG=$LANG
EOF

cat > $LFS/etc/inputrc << "EOF"
set horizontal-scroll-mode Off
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style none
"\eOd": backward-word
"\eOc": forward-word
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
"\eOH": beginning-of-line
"\eOF": end-of-line
"\e[H": beginning-of-line
"\e[F": end-of-line
EOF

cat > $LFS/etc/lsb-release << "EOF"
DISTRIB_ID="Stock Linux"
DISTRIB_RELEASE="rolling"
DISTRIB_CODENAME="stocklinux"
DISTRIB_DESCRIPTION="Stock Linux: The Real Power-User Experience"
EOF

cat > $LFS/etc/os-release << "EOF"
NAME="Stock Linux"
VERSION="rolling"
ID=stocklinux
PRETTY_NAME="Stock Linux rolling"
VERSION_CODENAME="rolling"
EOF

read -p "Choose your hostname (only A-B, a-b, 0-9, -)" HOSTNAME

cat > $LFS/etc/hostname << "EOF"
$HOSTNAME
EOF

cat > $LFS/etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

echo "export $(dbus-launch)" >> $LFS/etc/profile

UUID="$(blkid $ROOT_PARTITION -o value -s UUID)"

echo "UUID=${UUID}    /    ext4    defaults,noatime           0 1" >> $LFS/etc/fstab

UUID="$(blkid $BOOT_PARTITION_UEFI -o value -s UUID)"

echo "UUID=${UUID}    /boot/EFI    vfat    defaults    0 0" >> $LFS/etc/fstab

umount /dev/$ROOT_PARTITION

echo "Installation finished !"
# read -p "Installation finished ! Press [Enter] to reboot"
# shutdown -r now