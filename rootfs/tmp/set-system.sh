#!/bin/bash

# source config
source /tmp/base.conf

# Set hostname
echo "$hostname" > /etc/hostname

# Set users
echo "root:$password" | chpasswd
adduser --gecos $user --disabled-password $user
echo "$user:$password" | chpasswd
usermod -aG sudo,users $user

# Install desktop
if [ $desktop = xfce ]; then
	apt install -y parrot-desktop-xfce
elif [ $desktop = mate ]; then
	apt install -y parrot-desktop-mate
fi
