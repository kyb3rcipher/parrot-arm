#!/bin/bash

# Color variables
resetColor="\e[0m\e[0m"
redColor="\e[0;31m\e[1m"
greenColor="\e[0;32m\e[1m"
purpleColor="\e[0;35m\e[1m"
yellowColor="\e[0;33m\e[1m"
dot="${redColor}[${yellowColor}*${redColor}]${resetColor}"

# Check root privileges
[ "$EUID" -ne 0 ] && echo -e "$dot ${yellowColor}Please run with ${redColor}root ${yellowColor}or use ${greenColor}sudo${resetColor} " && exit

check_vmdb2=$(dpkg-query -W -f='${Status}' vmdb2 | grep "install ok installed")
# Install requirements
if [ "${check_vmdb2}" == "install ok installed" ]; then
    echo -e "\n[*] vmdb2 is already installed.\n"
	read -p "[?] Do you want to build the image? [Y/n]: " answer
	answer=${answer:Y}
    if [[ $answer =~ [Yy] ]]; then
        echo -e "[*] Starting build.sh"
        ./build.sh
    else
        echo -e "Quitting."
    fi
else
	echo -e "$yellowColor[!] Installing vmdb2... \n"
	sudo apt update && sudo apt install vmdb2
fi

