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

echo "Installing a basic system to chroot into..."
ROOT=$LFS squirrel get binutils linux-api-headers glibc gcc-lib-c++ m4 ncurses bash coreutils diffutils file findutils gawk grep gzip sed tar xz gettext perl python3 texinfo util-linux squirrel --chroot=$LFS -y 

echo "Installing the system, it can take a while !"

# Create the DNS configuration
echo "nameserver 8.8.8.8" > $LFS/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $LFS/etc/resolv.conf

# Mount temporary filesystems
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount --rbind /sys $LFS/sys
mount --make-rslave $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

# Chroot in the system
cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
mkdir -p /{home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab
EOF

cat > $LFS/etc/hosts << EOF
127.0.0.1  localhost stocklinux
::1        localhost
EOF

cat > $LFS/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > $LFS/etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
mkdir -p /var/squirrel/repos/{local,dist}
squirrel get man-pages iana-etc glibc zlib bzip2 xz zstd file readline m4 bc flex tcl expect dejagnu binutils libgmp libmpfr libmpc attr acl libcap shadow ncurses sed psmisc gettext grep bash libtool gdbm gperf expat inetutils less perl xmlparser intltool openssl kmod libelf python3 wheel coreutils check diffutils gawk findutils groff gzip iproute2 kbd libpipeline tar texinfo vim markupsafe jinja2 systemd dbus man-db procps util-linux e2fsprogs tzdata linux dhcpcd dracut wpasupplicant grub -y
pwconv
grpconv
EOF
read -p "What is the name of the user ? " USERNAME

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
useradd -m -G users,wheel,audio,video -s /bin/bash $USERNAME
EOF

read -p "Set the password of $USERNAME " PASSWD
cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
echo "$USERNAME:$PASSWD" | chpasswd
EOF

read -p "Set the password of root " PASSWD_ROOT
cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
echo "root:$PASSWD_ROOT" | chpasswd
cd /boot
dracut --kver=$(ls /lib/modules)
mv initramfs* initramfs-$(ls /lib/modules)-stocklinux.img
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