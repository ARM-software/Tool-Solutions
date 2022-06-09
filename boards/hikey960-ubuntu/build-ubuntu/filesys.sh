#!/bin/bash

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

if [[ $EUID -ne 0 ]]; then
   echo "This script must be started with: $ sudo $0" 
   exit 1
fi

echo -e "\nTo get more space create a new file system on the user partion. This will not impact the Linux install but will give 24 Gb of free space to use. If you have done this already and have existing data answer N to skip it and continue\n\n"

read -p "Do you want to make a new file system on the user partion (you will loose your old data)? " yn
case $yn in
    [Yy]*) /sbin/mkfs.ext4 /dev/sdd13;;
    [Nn]*) echo "Continuing with existing filesystem " ;;
    *) echo "Please answer yes or no, try again." ; exit;;
esac

if grep -q "sdd13" /etc/fstab; then
    echo "/dev/sdd13 already in /etc/fstab"
else
    echo "/dev/sdd13 /home/arm01/armnn-devenv ext4 defaults 0 2" >> /etc/fstab
fi

[ -d /home/arm01/armnn-devenv ] || mkdir /home/arm01/armnn-devenv
chown arm01 /home/arm01/armnn-devenv/.
chgrp arm01 /home/arm01/armnn-devenv/.
mount -a

# Setup Swap file
while true; do
    read -p "Do you wish to create a swapfile? " yn
    case $yn in
        [Yy]* ) echo "making swapfile..." ; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

[ -f /home/arm01/armnn-devenv/swapfile ] && rm -f /home/arm01/armnn-devenv/swapfile
dd if=/dev/zero of=/home/arm01/armnn-devenv/swapfile bs=1M count=4096
chown root:root /home/arm01/armnn-devenv/swapfile
chmod a-rwx,u+rw /home/arm01/armnn-devenv/swapfile
mkswap /home/arm01/armnn-devenv/swapfile
swapon /home/arm01/armnn-devenv/swapfile

if grep -q "swapfile" /etc/fstab; then
    echo "swapfile already in /etc/fstab"
else
    echo "/home/arm01/armnn-devenv/swapfile swap swap defaults 0 0" >> /etc/fstab
    mount -a
fi

echo "All done"

df
swapon --summary
