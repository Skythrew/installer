#!/usr/bin/env bash
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
# CONTRUBUTORS : Babilinx, Chevek, Crystal, Wamuu
# CREATED : october 2022
# REVISION: 23 october 2022
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

fdisk -l

read "On wich disk do you want to install the OS ? (ex: sda) " DISK_TO_INSTALL

echo "Stock Linux will be installed in $DISK_TO_INTALL. Ctrl+C to quit."

cfdisk /dev/$DISK_TO_INSTALL

read "What is the name of the root partition ? (ex: sda2) " ROOT_PARTITION
read "What is the name of the EFI partition ? (ex: sda1) " UEFI_PARTITION

mount /dev/$ROOT_PARTITION /mnt

export LFS="/mnt"

cd $LFS

wget http://stocklinux.hopto.org:8080/releases/lfs-temp-tools-r11.1-154-systemd+.tar.xz

tar -xpf lfs-temp-tools-r11.1-154-systemd+.tar.xz && rm lfs-temp-tools-r11.1-154-systemd+.tar.xz

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

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login

cd /var/squirrel/repos/local && rm * && touch INDEX && cd /

echo """import requests
r = request.get('http://stocklinux.hopto.org:8080/install.sh')
file = open('install.sh','wb')
file.write(r.content)
file.close
exit()""" > tmp.py

python3 tmp.py && rm tmp.py

squirrel sync && squirrel get squirrel --quiet && bash install.sh

squirrel get linux

squirrel get tzdata

# ls /usr/share/zoneinfo/

TZ_CONTINENT=Europe
TZ_CITY=Paris

ln -s /usr/share/zoneinfo/$TZ_CONTINENT/$TZ_CITY /etc/localtime

read "Wich keymap do you wanna use ? (ex: fr, us, etc)" KEYMAP

cat > /etc/vconsole.conf << "EOF"
KEYMAP=$KEYMAP
FONT=Lat2-Terminus16
EOF

read "Wich lang do you wanna use ? (ex: fr_FR.UTF-8, en_GB.ISO-8859-1, etc)" LANG

cat > /etc/locale.conf << "EOF"
LANG=$LANG
EOF

cat > /etc/inputrc << "EOF"

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

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Stock Linux"
DISTRIB_RELEASE="rolling"
DISTRIB_CODENAME="stocklinux"
DISTRIB_DESCRIPTION="Stock Linux: The Real Power-User Experience"
EOF

cat > /etc/os-release << "EOF"
NAME="Stock Linux"
VERSION="rolling"
ID=stocklinux
PRETTY_NAME="Stock Linux rolling"
VERSION_CODENAME="rolling"
EOF

read "Choose your hostname (only A-B, a-b, 0-9, -)" HOSTNAME

hostnamectl hostname $HOSTNAME

cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

echo "export $(dbus-launch)" >> /etc/profile

squirrel get dhcpcd

squirrel get wpasupplicant

echo "Now, follow a guide to write the fstab"
sleep 3

nano -w /etc/fstab

umount /dev/$ROOT_PARTITION
mount /dev/$UEFI_PARTITION /mnt

squirrel get grub-efi

grub-install --target=x86_64-efi --efi-directory=/mnt

squirrel get dracut && dracut --kver=5.19.0

grub-mkconfig -o /boot/grub/grub.cfg

rm /usr/lib/libbfd.a && rm /usr/lib/libbfd.la

read "What is the name of the user ? " USERNAME

useradd -m -G users,wheel,audio,video,sudo -s /bin/bash $USERNAME    # Admin access user
passwd $USERNAME

read "Installation finished ! Press [Enter] to reboot"

shutdown -r now
