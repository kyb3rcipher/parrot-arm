# Parrot ARM

Repository for Parrot on the ARM platform. All credit for the first build and first version of the code goes to @kyb3rcipher. 

## Tested hardware

Raspberry Pi 3 B+, 4 B 

## Use

This repository contains two main scripts, `rpi.sh` to create the root filesystem, and `image-creation.sh` to build the image. Before starting them, you need to install some packages on a Parrot OS system. 

#### Requirements
Just run:

    ./requirements.sh

#### Build

Once all the `requirements.sh` script packages have been installed, open a terminal window and run `sudo ./rpi.sh`. After that you can create the image using `sudo ./image-creation.sh`. 

Current Parrot Home image size with MATE and compiled for ARM64: 5.4 GB

#### Flash OS image

Use Balena Etcher 1.6.0+ to flash the image in the micro sd card. 


## Customize

To configure and customize your personal image you must create a copy of the base.conf file with the name **custom.conf**. Then edit or add the variables you want to customize to the file you created.

Variables explanation:

- user - non-root username.
- password - password of non-root user and root user.
- hostname - host system name.
- timezone - time zone you can see the list [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).
- locales - locales of the system (such as language) you can see the list [here](https://docs.moodle.org/dev/Table_of_locales#Table).
- architecture - arm system architecture options are armhf or arm64.
- dns - internet dns system (8.8.8.8 for google, by default cloudflare).
- desktop - desktop environment to be installed the options are: xfce, mate, gnome, i3. 
- install_desktop - install desktop environment defined by desktop variable. (option "yes" or "no")
- install_userland - install raspberry userland firmware. (option "yes" or "no")
- install_nexmon - install nexmon wireless drivers. (option "yes" or "no")
- parrot_edition - parrot edition the options are home or security.
- parrot_mirror - server where the system and packages are downloaded from you can see the options in our [list of mirrors](https://parrotsec.org/docs/mirrors-list.html#other-mirrors-for-manual-configuration).
- parrot_release - debootstrap script release ⚠️

Notes: the variables that contain the symbol ⚠️ are because preferably they should not be modified.
