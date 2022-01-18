#!/bin/bash

NOCOLOR='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

builder_packages="debootstrap qemu-user-static wget git"
image_creation_packages="binfmt-support dosfstools qemu-user-static rsync wget lsof git parted dirmngr e2fsprogs systemd-container debootstrap xz-utils kmod udev dbus gnupg gnupg-utils debian-archive-keyring"

echo -e "${YELLOW}[*] Updating the repositories ${NOCOLOR}" && sudo apt update

echo -e "\n${GREEN}[!] Installing the requirements:${NOCOLOR} ${builder_packages} ${image_creation_packages} \n"

sudo apt install $builder_packages $image_creation_packages

echo -e "\nRequirements installed!"
