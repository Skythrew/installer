#! /bin/sh

# This is an example configuration script. For OS-Installer to use it, place it at:
# /etc/os-installer/scripts/configure.sh
# The script gets called with the environment variables from the install script
# (see install.sh) and these additional variables:
# OSI_USER_NAME          : User's name. Not ASCII-fied
# OSI_USER_AUTOLOGIN     : Whether to autologin the user
# OSI_USER_PASSWORD      : User's password. Can be empty if autologin is set.
# OSI_FORMATS            : Locale of formats to be used
# OSI_TIMEZONE           : Timezone to be used
# OSI_ADDITIONAL_SOFTWARE: Space-separated list of additional packages to install
# OSI_ADDITIONAL_FEATURES: Space-separated list of additional features chosen

# sanity check that all variables were set
if [ -z ${OSI_LOCALE+x} ] || \
   [ -z ${OSI_DEVICE_PATH+x} ] || \
   [ -z ${OSI_DEVICE_IS_PARTITION+x} ] || \
   [ -z ${OSI_DEVICE_EFI_PARTITION+x} ] || \
   [ -z ${OSI_USE_ENCRYPTION+x} ] || \
   [ -z ${OSI_ENCRYPTION_PIN+x} ] || \
   [ -z ${OSI_USER_NAME+x} ] || \
   [ -z ${OSI_USER_AUTOLOGIN+x} ] || \
   [ -z ${OSI_USER_PASSWORD+x} ] || \
   [ -z ${OSI_FORMATS+x} ] || \
   [ -z ${OSI_TIMEZONE+x} ] || \
   [ -z ${OSI_ADDITIONAL_SOFTWARE+x} ] || \
   [ -z ${OSI_ADDITIONAL_FEATURES+x} ]
then
    echo "Installer script called without all environment variables set!"
    exit 1
fi

echo 'Configuration started.'

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
squirrel get man-pages iana-etc glibc zlib bzip2 xz zstd file readline m4 bc flex tcl expect dejagnu binutils libgmp libmpfr libmpc attr acl libcap shadow ncurses sed psmisc gettext grep bash libtool gdbm gperf expat inetutils less perl xmlparser intltool openssl kmod libelf python3 wheel coreutils check diffutils gawk findutils groff gzip iproute2 kbd libpipeline tar texinfo vim markupsafe jinja2 systemd dbus man-db procps util-linux e2fsprogs gcc tzdata linux linux-firmware dhcpcd dracut wpasupplicant grub -y
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
mv initramfs* initramfs-\$(ls /lib/modules)-stocklinux.img
mount /dev/$UEFI_PARTITION /mnt
grub-install --target=x86_64-efi --efi-directory=/mnt
grub-mkconfig -o /boot/grub/grub.cfg
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

while  [ $IS_HOSTNAME_VALID = 0 ]; do
  read -p "Choose your hostname (only A-B, a-b, 0-9, -) " CHROOT_HOSTNAME
  test_if_hostname_is_valid
  if [ $IS_HOSTNAME_VALID = 0 ]; then
    echo "${COLOR_YELLOW}Hostname : $CHROOT_HOSTNAME is not valid. Try again.${COLOR_RESET}"
  fi
done

echo $CHROOT_HOSTNAME > $LFS/etc/hostname

cat > $LFS/etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

echo "export \$(dbus-launch)" >> $LFS/etc/profile

UUID="$(blkid /dev/$ROOT_PARTITION -o value -s UUID)"
echo "UUID=$UUID    /    ext4    defaults,noatime           0 1" >> $LFS/etc/fstab
UUID="$(blkid /dev/$UEFI_PARTITION -o value -s UUID)"
echo "UUID=$UUID    /boot/EFI    vfat    defaults    0 0" >> $LFS/etc/fstab

echo
echo 'Configuration completed.'

exit 0
