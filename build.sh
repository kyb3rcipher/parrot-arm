#!/bin/bash

# Color variables
resetColor="\e[0m\e[0m"
redColor="\e[0;31m\e[1m"
blueColor="\e[0;34m\e[1m" 
cyanColor="\e[01;96m\e[1m"
greenColor="\e[0;32m\e[1m"
purpleColor="\e[0;35m\e[1m"
yellowColor="\e[0;33m\e[1m"
roseColor="\e[38;5;199m\e[1m"
dot="${redColor}[${yellowColor}*${redColor}]${resetColor}"

# CTRL+C exit function
trap ctrl_c INT
ctrl_c() {
    echo -e "\n$dot$yellowColor Exiting...$resetColor"
    exit
}

# Check root privileges
[ "$EUID" -ne 0 ] && echo -e "$dot ${yellowColor}Please run with ${redColor}root ${yellowColor}or use ${greenColor}sudo${resetColor} " && exit

ARGUMENT_LIST=(
  "edition"
  "device"
  "architecture"
  "user"
  "password"
  "desktop"
  "hostname"
  "verbose"
)

# Read arguments
opts=$(getopt \
  --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
  --name "$(basename "$0")" \
  --options "" \
  -- "$@"
)
eval set --$opts
while [[ $# -gt 0 ]]; do
  case "$1" in
	--edition)
		edition=$2
		shift 2
		;;
    --device)
    	device=$2
		shift 2
		;;
    --architecture)
		architecture=$2
	    shift 2
		;;
    --user)
		user=$2
	    shift 2
		;;
    --password)
		password=$2
	    shift 2
		;;
    --desktop)
		desktop=$2
	    shift 2
		;;
    --hostname)
		hostname=$2
	    shift 2
		;;
	--verbose)
		verbose=$2
		shift 2
		;;
    *)
      break
      ;;
  esac
done

# Set default config 
[ -z $editon ] && edition=home
[ -z $device ] && device=rpi
[ -z $architecture ] && architecture=armhf
[ -z $user ] && user=parrot
[ -z $password ] && password=parrot
[ -z $desktop ] && desktop=no
[ -z $hostname ] && hostname=parrot
[ -z $verbose ] && verbose=no

# source config file
[ -f config.txt ] && source config.txt

cat > rootfs/tmp/base.conf <<EOM
user="$user"
password="$password"
desktop="$desktop"
edition="$edition"
hostname="$hostname"
EOM

# Banner
clear
echo -e "${greenColor} __        __   __   __  ___     ${redColor}     __           ${yellowColor} __               __   ___  __  "
echo -e "${greenColor}|__)  /\  |__) |__) /  \  |      ${redColor}/\  |__)  |\/|    ${yellowColor}|__) |  | | |    |  \ |__  |__) "
echo -e "${greenColor}|    /~~\ |  \ |  \ \__/  |     ${redColor}/~~\ |  \  |  |    ${yellowColor}|__) \__/ | |___ |__/ |___ |  \ \n"
echo -e " ${purpleColor}Device & architecture: ${roseColor}Raspberry Pi $resetColor- ${cyanColor}$architecture"
echo -e " ${purpleColor}Parrot Edition: ${cyanColor}$edition"
#echo -e " ${purpleColor}User & password: ${cyanColor}$user $resetColor- $password"
echo -e " ${purpleColor}User: ${cyanColor}$user"
echo -e " ${purpleColor}Password: ${cyanColor}$password"
echo -e " ${purpleColor}Hostname: ${cyanColor}$hostname"
echo -e " ${purpleColor}Desktop: ${cyanColor}$desktop"
echo -e " ${purpleColor}Verbose: ${cyanColor}$verbose$resetColor\n"
sleep 3

# Create work dirs and delete them if they exists
echo -e "$dot$yellowColor Creating work dirs...$resetColor"
[ -d work_dir ] && rm -rf work_dir
[ -d out_dir ] && rm -rf out_dir
mkdir work_dir
mkdir out_dir

# Copy recipe
echo -e "$dot$yellowColor Creating build recipe...$resetColor\n"
cp recipes/$device-$architecture.yaml work_dir/recipe.yaml

# Build recipe (system and image)
echo -e "$dot$greenColor Bulding system and image...$resetColor"
if [ $verbose = yes ]; then
	vmdb2 --rootfs-tarball=work_dir/parrot-tarball.tar.gz --output out_dir/parrot.img work_dir/recipe.yaml --verbose --log work_dir/build.log
else
	vmdb2 --rootfs-tarball=work_dir/parrot-tarball.tar.gz --output out_dir/parrot.img work_dir/recipe.yaml --log work_dir/build.log
fi

# Check construction status
returnValue="$?"
[ "$returnValue" -ne 0 ] && echo -e "$redColor[!] Error, retry$resetColor" && exit

# Adding build readme
echo -e "\n$dot$greenColor Final stapes...$resetColor"
cat > out_dir/readme.txt <<EOM
Device: Raspberry Pi 3/4
Parrot Edition: $edition
Architecture: $architecture
Desktop: $desktop
Total build time: $SECONDS seconds
EOM
