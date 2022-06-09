#!/bin/bash

# Setup Swap file
while true; do
    read -p "Do you wish to create a swapfile? " yn
    case $yn in
        [Yy]* ) echo "making swapfile..." ; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

[ -f $HOME/swapfile ] && rm -f $HOME/swapfile
dd if=/dev/zero of=$HOME/swapfile bs=1M count=2048
chown root:root $HOME/swapfile
chmod a-rwx,u+rw $HOME/swapfile
mkswap $HOME/swapfile
swapon $HOME/swapfile

if grep -q "swapfile" /etc/fstab; then
    echo "swapfile already in /etc/fstab"
else
    echo "/home/rock/swapfile swap swap defaults 0 0" >> /etc/fstab
    mount -a
fi

echo "All done"

df
swapon --summary

