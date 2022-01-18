#!/bin/bash
#
# Parrot OS ARM Builder
# Device: Raspberry Pi 3/4/400
# By: Kyb3r Cipher <kyb3rcipher.com>
#

#source kyb3r library
source <(curl -s https://raw.githubusercontent.com/kyb3rcipher/shell-library/main/text.sh)

# check root priviliges
[ "$EUID" -ne 0 ] && echo -e "${dot} ${yellowColor}Please run with ${redColor}root ${yellowColor}or use ${greenColor}sudo${resetColor}" 1>&2 && exit

#check old builders
[ -d work_dir ] && echo -e "${dot_purple} ${yellowColor}Old build detected!, for continue delete that build with: ${turquoiseColor}rm -rf work_dir${resetColor}" && exit

#-----------------------------------------------------
# builder
#-----------------------------------------------------
# functions for script
function system_exec(){
	LANG=C chroot $rootfs $@
}

#banner
banner(){
clear
echo -e "${greenColor} __        __   __   __  ___     ${redColor}     __           ${yellowColor} __               __   ___  __  "
echo -e "${greenColor}|__)  /\  |__) |__) /  \  |      ${redColor}/\  |__)  |\/|    ${yellowColor}|__) |  | | |    |  \ |__  |__) "
echo -e "${greenColor}|    /~~\ |  \ |  \ \__/  |     ${redColor}/~~\ |  \  |  |    ${yellowColor}|__) \__/ | |___ |__/ |___ |  \  ${resetColor}\n"
}
banner_config(){
echo -e "The configuration is:"
if [ $parrot_edition = security ]; then
echo -e " ${purpleColor}Edition: ${cyanColor}Security"
else
echo -e " ${purpleColor}Edition: ${cyanColor}Home"
fi
echo -e " ${purpleColor}Device & architecture: ${roseColor}Raspberry Pi 3/3+/4/400 - ${cyanColor}$architecture"
echo -e " ${purpleColor}Hostname: ${cyanColor}$hostname"
echo -e " ${purpleColor}User & password ${cyanColor}$user - $password"
echo -e " ${purpleColor}Timezone & Locales: ${cyanColor}$locales - $timezone"
[ $install_desktop = yes ] && echo -e " ${purpleColor}Install desktop: ${cyanColor}$install_desktop ($desktop)"
[ $install_nexmon = yes ] && echo -e " ${purpleColor}Install nexmon: ${cyanColor}$install_nexmon"
[ $install_userland = yes ] && echo -e " ${purpleColor}Install userland: ${cyanColor}$install_userland"
echo -e " $resetColor"
sleep 10
}

# Prepare work space
# source config
source base.conf
# four custom config
[ -f custom.conf ] && source custom.conf
# show banner
banner && banner_config
# create work dirs
mkdir work_dir
rootfs="work_dir/rootfs"

# create rootfs system (with debootstrap first and second stage)
debootstrap --foreign --arch=$architecture --include="gnupg ca-certificates" $parrot_release $rootfs $parrot_mirror
# copy qemu bin for system_exec
echo -e "${redColor}I: ${yellowColor}Installing qemu-bin for system_exec...${resetColor}"
if [ $architecture = "armhf" ]; then
	cp /usr/bin/qemu-arm-static $rootfs/usr/bin
else
	cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin 
fi
system_exec /debootstrap/debootstrap --second-stage
system_exec apt update

# Prepare system
#install packages
base_pkgs="sudo wget gnupg locales ca-certificates net-tools"
pentesting_pkg="nmap"
extra_pkgs="neovim"
system_exec apt install -y $base_pkgs $extra_pkg
#install repos
#echo "deb http://deb.debian.org/debian bullseye main contrib non-free" > $rootfs/etc/apt/sources.list.d/debian.list

# Set system

#set hosts
text "Setting hosts..." yellow
echo "$hostname" > $rootfs/etc/hostname
cat > $rootfs/etc/hosts <<EOM
127.0.1.1       $hostname
127.0.0.1       localhost
::1             localhostnet.ifnames=0 ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOM

#set dns servers
text "Setting DNS..." yellow
rm $rootfs/etc/resolv.conf
echo "nameserver $dns" > $rootfs/etc/resolv.conf

#set users
text "Setting users..." yellow
system_exec bash <<EOF
echo "root:$password" | chpasswd
adduser --disabled-password --gecos "" $user
usermod -a -G "sudo,users" $user
echo "$user:$password" | chpasswd
cp -rT /etc/skel /root
cp -rT /etc/skel /home/$user
EOF

#set fstab
text "Setting fstab..." yellow
cat > $rootfs/etc/fstab <<EOM
# <file system>   <dir>           <type>  <options>         <dump>  <pass>
proc              /proc           proc    defaults          0       0
/dev/mmcblk0p1    /boot           vfat    defaults          0       2
/dev/mmcblk0p2    /               ext4    defaults,noatime  0       1
EOM

#install desktop
if [ $install_desktop = yes ]; then
banner && text "Installing desktop..." green
system_exec apt install -y parrot-desktop-$desktop
fi

# Install raspbery repos
echo "deb http://archive.raspberrypi.org/debian bullseye main" > $rootfs/tmp/raspberry-apt.txt
mv $rootfs/tmp/raspberry-apt.txt $rootfs/etc/apt/sources.list.d/raspberry.list
system_exec apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7FA3303E
system_exec apt update

# Install pi-config
system_exec apt install -y raspi-config

# Install userland
if [ $install_userland = yes ]; then
system_exec apt install -y raspberrypi-userland
fi

# Install kernel
banner && text "Installing kernel..."
system_exec apt install -y raspberrypi-kernel raspberrypi-bootloader
#install boot config
echo "net.ifnames=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootwait" > $rootfs/boot/cmdline.txt
echo "hdmi_force_hotplug=1" > $rootfs/boot/config.txt
if [ $architecture = arm64 ]; then
	echo "arm_64bit=1" > $rootfs/boot/config.txt
fi

# Desabilite raspberry repos
rm $rootfs/etc/apt/sources.list.d/raspberry.list
system_exec apt update
