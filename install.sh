#!/bin/bash
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
# REVISION: 30 january 2023
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

if [ "$EUID" -ne 0 ]
  then echo "The script needs root rights"
  exit
fi


COLOR_YELLOW=$'\033[0;33m'
COLOR_GREEN=$'\033[0;32m'
COLOR_RED=$'\033[0;31m'
COLOR_LIGHTBLUE=$'\033[1;34m'
COLOR_WHITE=$'\033[1;37m'
COLOR_LIGHTGREY=$'\e[37m'
COLOR_RESET=$'\033[0m'
C_RESET=$'\e[0m'

VALID_HOSTNAME_REGEX="^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$"

IS_HOSTNAME_VALID=0

test_if_hostname_is_valid()
{
  if [ ${#CHROOT_HOSTNAME} -le 255 ]; then
    if [[ "$CHROOT_HOSTNAME" =~ $VALID_HOSTNAME_REGEX ]]; then
		IS_HOSTNAME_VALID=1
	else
		IS_HOSTNAME_VALID=0
    fi
  else
    IS_HOSTNAME_VALID=0
  fi
}


create_passwd()
{
  echo "Create password for $1 :"
   read -s ATTEMPT1
	echo "Retype password :"
   read -s ATTEMPT2
}


verify_password_concordance()
{
  while [[ "$ATTEMPT1" != "$ATTEMPT2" ]]; do
    echo "${COLOR_YELLOW}The passwords dosn't match. Try again.${COLOR_RESET}"
    create_passwd
	done
  PASSWD=$ATTEMPT1
}


echo "Welcome into the installation script of Stock Linux"
echo """${COLOR_YELLOW}Dragons ahead !
This script is still in developpement, use it with precautions !
We are not responsable for enything that can appears pending the installation (data loss, break computer, burning house, WWIII, etc)${COLOR_RESET}"""

echo "Installing evox on the host system..."
wget https://github.com/stock-linux/evox/archive/main.tar.gz
tar -xf main.tar.gz
ln -s evox-main evox
ln -s $PWD/evox/evox-x /bin/evox

echo -e "#!/bin/sh\npython3 $PWD/evox/evox/main.py \"\$@\"" > evox/evox-x
chmod +x evox/evox-x
pip3 install -r evox/requirements.txt

# Create the basic /etc/evox.conf
echo "Creating the basic evox.conf..."
touch /etc/evox.conf
echo "REPO base http://packages.stocklinux.org/base" >> /etc/evox.conf

echo "Everything is configured !"

echo "Disks:"
lsblk -d -o NAME,SIZE
echo "\n"

read -p "On wich disk do you want to install the OS ? (ex: sda) " DISK_TO_INSTALL

echo "Stock Linux will be installed in $DISK_TO_INTALL. Ctrl+C to quit."
cfdisk /dev/$DISK_TO_INSTALL
read -p "What is the name of the root partition ? (ex: sda2) " ROOT_PARTITION
read -p "What is the name of the EFI partition ? (ex: sda1) " UEFI_PARTITION

mkfs.ext4 /dev/$ROOT_PARTITION
mkfs.fat -F 32 /dev/$UEFI_PARTITION

mount /dev/$ROOT_PARTITION /mnt

export LFS="/mnt"
cd $LFS

# Init evox
ROOT=$LFS evox init

# Sync evox
ROOT=$LFS evox sync

# Create the distro structure
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
mkdir -p $LFS/mnt

ln -s usr/bin $LFS/bin
ln -s usr/lib $LFS/lib
ln -s usr/sbin $LFS/sbin
mkdir -p $LFS/lib64
mkdir -p $LFS/usr/lib32
ln -s usr/lib32 $LFS/lib32

mkdir -p $PKG/{home,mnt,opt,srv}
mkdir -p $PKG/etc/{opt,sysconfig}
mkdir -p $PKG/lib/firmware
mkdir -p $PKG/media/{floppy,cdrom}
mkdir -p $PKG/usr/{,local/}{include,src}
mkdir -p $PKG/usr/local/{bin,lib,sbin}
mkdir -p $PKG/usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -p $PKG/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -p $PKG/usr/{,local/}share/man/man{1..8}
mkdir -p $PKG/var/{cache,local,log,mail,opt,spool}
mkdir -p $PKG/var/lib/{color,misc,locate}

ln -sfv ../run $PKG/var/run
ln -sfv ../run/lock $PKG/var/lock

ln -sv ../proc/self/mounts $PKG/etc/mtab

touch $PKG/var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp $PKG/var/log/lastlog
chmod -v 664  $PKG/var/log/lastlog
chmod -v 600  $PKG/var/log/btmp


# Create the DNS configuration
echo "nameserver 8.8.8.8" > $LFS/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $LFS/etc/resolv.conf

echo "Installing a basic system to chroot into..."
ROOT=$LFS evox get iana-etc glibc zlib bzip2 xz zstd file readline m4 bc flex tcl expect dejagnu gmp mpfr mpc attr acl libcap shadow gcc ncurses sed psmisc gettext bison grep bash libtool gperf expat inetutils less perl perl-xmlparser intltool openssl kmod libelf libffi python python-wheel coreutils check diffutils findutils grub gzip iproute2 kbd libpipeline tar vim python-markupsafe python-jinja systemd dbus procps-ng util-linux e2fsprogs dhcpcd wpa_supplicant kernel linux-firmware dracut evox -y 

echo "Installing the system, it can take a while !"

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

cat > $LFS/usr/bin/evox << "EOF"
#!/bin/bash
python3 /usr/lib/evox/evox/main.py "$@"
EOF

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
ln -s bash /bin/sh
chmod +x /usr/bin/evox

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

systemd-machine-id-setup
systemctl preset-all
systemctl disable systemd-networkd
systemctl disable systemd-sysupdate

pip3 install -r /usr/lib/evox/requirements.txt
pwconv
grpconv

EOF

read -p "What is the name of the user ? " USERNAME

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
useradd -m -G users,wheel,audio,video -s /bin/bash $USERNAME
chown -R $USERNAME:$USERNAME /home/$USERNAME
EOF

create_passwd $USERNAME
verify_password_concordance

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
echo -e "$PASSWD\n$PASSWD" | passwd $USERNAME
EOF

create_passwd "root"
verify_password_concordance

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
echo -e "$PASSWD\n$PASSWD" | passwd root
cd /boot
dracut --kver=\$(ls /lib/modules)
mv initramfs* initramfs-\$(ls /lib/modules)-stock.img
mount /dev/$UEFI_PARTITION /mnt
grub-install --target=x86_64-efi --efi-directory=/mnt
EOF

# ls /usr/share/zoneinfo/
TZ_CONTINENT=Europe
TZ_CITY=Paris
ln -s /usr/share/zoneinfo/$TZ_CONTINENT/$TZ_CITY $LFS/etc/localtime

read -p "What keymap do you want to use ? (ex: fr, us, etc) " CHROOT_KEYMAP

echo "KEYMAP=$CHROOT_KEYMAP" > $LFS/etc/vconsole.conf

cat >> $LFS/etc/vconsole.conf << "EOF"
FONT=Lat2-Terminus16
EOF

read -p "What lang do you want to use ? (ex: fr_FR.UTF-8, en_GB.ISO-8859-1, etc) " CHROOT_LANG
echo "LANG=$CHROOT_LANG" > $LFS/etc/locale.conf
echo "LC_ALL=$CHROOT_LANG" >> $LFS/etc/environment
echo "LANG=$CHROOT_LANG" >> $LFS/etc/environment

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

cat > $LFS/etc/os-release << "EOF"
NAME="Stock Linux"
VERSION="Sunbird (Alpha)"
ID=stocklinux
PRETTY_NAME="Stock Linux Sunbird (Alpha)"
VERSION_CODENAME="sunbird-alpha"
EOF

cat << EOF | chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" PS1='(lfs chroot) \u:\w\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login
grub-mkconfig -o /boot/grub/grub.cfg
EOF

while  [ $IS_HOSTNAME_VALID = 0 ]; do
  read -p "Choose your hostname (only A-B, a-b, 0-9, -) " CHROOT_HOSTNAME
  test_if_hostname_is_valid
  if [ $IS_HOSTNAME_VALID = 0 ]; then
    echo "${COLOR_YELLOW}Hostname : $CHROOT_HOSTNAME is not valid. Try again.${COLOR_RESET}"
  fi
done

echo $CHROOT_HOSTNAME > $LFS/etc/hostname
echo 'XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/usr/share"' >> $LFS/etc/environment
cat > $LFS/etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

UUID="$(blkid /dev/$ROOT_PARTITION -o value -s UUID)"
echo "UUID=$UUID    /    ext4    defaults,noatime           0 1" >> $LFS/etc/fstab
UUID="$(blkid /dev/$UEFI_PARTITION -o value -s UUID)"
echo "UUID=$UUID    /boot/EFI    vfat    defaults    0 0" >> $LFS/etc/fstab

umount -R /dev/$ROOT_PARTITION

read -p "Installation finished ! Press [Enter] to reboot"

shutdown -r now
