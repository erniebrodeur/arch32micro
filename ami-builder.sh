#!/bin/sh
# I really should do this in py or rb, and will before I go to far.  This is just a skeleton.
# This file used https://github.com/yejun/ec2build as a reference, but since it has different
# goals in mind, it is more of a guide then it is copied and extended.
# This property is covered under the GPL or any other permissive license you feel like.

# Dependancies: sudo.

# WARNING DANGER WILL ROBINSON.
# WARNING DANGER WILL ROBINSON.
# WARNING DANGER WILL ROBINSON.
# WARNING DANGER WILL ROBINSON.
# I really haven't spent all that much work making this script safe.  Unless you know what you are
# doing, I wouldn't run it.  For now its just a guide, the individual steps do work and all the steps
# should be self contained, but well be careful.

### Tweakables
# everything you want to customize is in this section.
PACKS_BASE="pcre glib2 module-init-tools libgcrypt popt perl openssl kbd linux-firmware mkinitcpio-busybox  gen-init-cpio  which  mkinitcpio  less licenses logrotate texinfo groff man-db man-pages nano expat libarchive libfetch pacman pacman libnl procps psmisc tcp_wrappers tar vi wget openssh sudo"
ROOTDEV=/dev/xvdm
ROOTDEV1=/dev/xvdm1
ROOTDEV2=/dev/xvdm2

# These are extra base packs, the idea being don't edit PACKS_MAIN unless you absolutely have too.
# instead just uncomment/tweak one of these and the string is cat'ed together during install.

#PACKS_VIM
#PACKS_EMACS

# these are packs from the AUR that should be installed by default.  They are not compiled
# in this script, so they must be .xz files.
# DO NOT INCLUDE THE KERNEL!  we use a special handler to make sure it only gets installed
# once and we use the one we want.
AURPACKS=""

# our kernel, from the AUR.
KERNELPACK="kernel26-ec2"

# DO NOT EDIT BELOW HERE.
# Well, you can, but you should know what you are doing.

### Setup filesystem

# setup env
WORKINGDIR="./newroot"
mkdir -p $WORKINGDIR


# build our root device
#dd if=/dev/zero of=$ROOTDEV bs=1M count=2000

fdisk $ROOTDEV <<EOF
n
p


+100M
n
p



w
EOF
mkfs.ext2 $ROOTDEV1
mkfs.ext4 $ROOTDEV2

# setup new root.
mount $ROOTDEV2 ./newroot
mkdir -p ./newroot/boot
mount $ROOTDEV1 ./newroot/boot

# concat pack lists from above together, later.
ALLPACKS=$PACKS_BASE

### Start building arch
# build the basic system
#linux32 mkarchroot -f -C ./pacman.conf newroot pcre glib2 module-init-tools libgcrypt popt perl openssl kbd linux-firmware mkinitcpio-busybox gen-init-cpio which mkinitcpio less licenses logrotate texinfo groff man-db man-pages nano expat libarchive libfetch pacman pacman libnl procps psmisc tcp_wrappers tar vi wget

linux32 mkarchroot -f -C ./pacman.conf newroot $ALLPACKS

# setup the custom AUR stuff
mkdir -p ./newroot/opt/AUR
cp -Rv AUR ./newroot/opt/

# -r "bash" starts up a nice chroot env with all our mounts done. thanks Allan!
# I need to put an arch catch here, since this may implode on 32, haven't tested.
# TODO: make this glob, or regex, or something.
linux32 mkarchroot -r "pacman --noconfirm -U /opt/AUR/kernel26-ec2-2.6.38-1-i686.pkg.tar.xz /opt/AUR/kernel26-ec2-headers-2.6.38-1-i686.pkg.tar.xz" newroot

### Boot loader
# so my current theory is that I don't put a boot loader at all. Instead, I generate a menu-list
# and xen/pv-grub does the heavy lifting.

mkdir -p ./newroot/boot/grub
cat << EOF > ./newroot/boot/grub/menu.lst
default 0
timeout 4
hiddenmenu

title  Arch Linux
  root   (hd0,0)
  kernel /vmlinuz26-ec2 root=/dev/xvda2 console=hvc0 ip=dhcp spinlock=tickless ro
EOF

### Modified Files.
# fix mkinitcpio
# cp ./mkinitcpio.conf ./newroot/etc/mkinitcpio.conf

# secure sshd
sed -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' -i ./newroot/etc/ssh/sshd_config
sed -e 's/#UseDNS yes/UseDNS no/' -i ./newroot/etc/ssh/sshd_config

# setup our fstab with uuid's.
# TODO: make it work with the correct loop's, not just the first two.
cat << EOF > ./newroot/etc/fstab
$(blkid -c /dev/null -s UUID -o export $ROOTDEV2) /     auto    defaults,relatime 0 1
$(blkid -c /dev/null -s UUID -o export $ROOTDEV1) /boot     auto    defaults,relatime 0 1
none  /proc proc    nodev,noexec,nosuid 0 0
none  /dev/pts devpts defaults 0 0
none  /dev/shm tmpfs nodev,nosuid 0 0
EOF

# setup our resolv.conf
echo "nameserver 172.16.0.23" > ./newroot/etc/resolv.conf

# fix inittab up so it will output to console and not spawn ttys.
cat << EOF > ./newroot/etc/inittab
id:3:initdefault:
rc::sysinit:/etc/rc.sysinit
rs:S1:wait:/etc/rc.single
rm:2345:wait:/etc/rc.multi
rh:06:wait:/etc/rc.shutdown
su:S:wait:/sbin/sulogin -p
ca::ctrlaltdel:/sbin/shutdown -t3 -r now
# This will enable the system log.
c0:12345:respawn:/sbin/agetty 38400 hvc0 linux
EOF

# fix hosts.deny nonsense.
cat << EOF > ./newroot/etc/hosts.deny
#
# /etc/hosts.deny
#
# End of file
EOF

#rc.conf
cat <<EOF > ./newroot/etc/rc.conf
LOCALE="en_US.UTF-8"
TIMEZONE="UTC"
MOD_AUTOLOAD="no"
USECOLOR="yes"
USELVM="no"
DAEMONS=( syslog-ng sshd crond ec2 )
EOF


# setup sudoers
# add this for amazon?  seems all the instances have it.

echo "%wheel ALL=\(ALL\) NOPASSWD: ALL" >> ./newroot/etc/sudoers.d/amazon

### Close up
# flag for first boot
# another amazon thing I need to test
touch ./newroot/root/firstboot

# wrap up env

echo "Cleaning up."

rm newroot.lock
umount newroot/boot
umount newroot

