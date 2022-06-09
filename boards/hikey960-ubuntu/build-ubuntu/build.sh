#!/bin/bash -e

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

function IsPackageInstalled() {
  dpkg -s "$1" > /dev/null 2>&1
}

# add required packages on the host
packages="binfmt-support qemu-user qemu-user-static android-tools-fsutils fastboot e2tools zerofree git"
for package in $packages; do
  if ! IsPackageInstalled $package; then
    sudo apt-get install -y $package
  fi
done

# everything done in ubuntu/ sub-directory 
mkdir ubuntu
cp config-fs.sh ubuntu
cp filesys.sh ubuntu
cp -r modules.tar.gz ubuntu

# download mali userspace driver if needed
[ -f mali-G71_r9p0-01rel0_linux_1fbdev.tar.gz ] || wget https://developer.arm.com/-/media/Files/downloads/mali-drivers/user-space/HiKey%20960/mali-G71_r9p0-01rel0_linux_1fbdev.tar.gz
tar xvfz mali-G71_r9p0-01rel0_linux_1fbdev.tar.gz -C ubuntu
cp mali-link ubuntu
pushd ubuntu

# download Ubuntu base filesystem image
[ -f sysroot.tar.gz ] || wget http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.5/release/ubuntu-base-16.04.5-base-arm64.tar.gz -O ./sysroot.tar.gz
[ -d sysroot/ ] && sudo rm -rf sysroot/
mkdir -p sysroot
sudo tar xf ./sysroot.tar.gz -C sysroot
sudo cp "$(which qemu-aarch64-static)" ./sysroot/usr/bin/
sudo cp config-fs.sh sysroot/root/

# wireless firmware 
sudo mkdir -p sysroot/lib/firmware/ti-connectivity
if [[ ! -d wlanfw ]]; then
  git clone git://git.ti.com/wilink8-wlan/wl18xx_fw.git wlanfw
fi
sudo cp -f wlanfw/wl18xx-fw-4.bin sysroot/lib/firmware/ti-connectivity/.

sudo cp -r fbdev/* sysroot/usr/lib
sudo chmod og+rx sysroot/usr/lib/libmali.so
sudo mkdir sysroot/usr/lib/aarch64-linux-gnu/mali-G71_r9p0_linux-arm64_1/
sudo cp -r fbdev sysroot/usr/lib/aarch64-linux-gnu/mali-G71_r9p0_linux-arm64_1/.
sudo chmod og+rx sysroot/usr/lib/aarch64-linux-gnu/mali-G71_r9p0_linux-arm64_1/fbdev
sudo chmod og+rx sysroot/usr/lib/aarch64-linux-gnu/mali-G71_r9p0_linux-arm64_1/fbdev/libmali.so
sudo tar xvf modules.tar.gz -C sysroot/lib
sudo cp mali-link sysroot/usr/sbin
 
# run the extra configuration steps in a chroot using qemu
sudo chroot  sysroot bash -c "chmod +x /root/config-fs.sh"
sudo chroot sysroot bash -c "LC_ALL=C /root/config-fs.sh"
sudo chroot sysroot bash -c "rm -f /root/config-fs.sh"
sudo rm sysroot/usr/bin/qemu-aarch64-static

# extra file to setup user partion and swap after first boot
sudo cp filesys.sh sysroot/home/arm01/

# make new filesystem, mount, and copy contents
dd if=/dev/zero of=./system.img bs=4M count=1 seek=1023
mkfs.ext4 -F ./system.img
sudo mkdir -p mount_loop
sudo mount -o loop ./system.img mount_loop
sudo cp -a ./sysroot/. mount_loop/
sudo umount mount_loop

# convert to sparse image format
[ -e system.simg ] && rm -rf system.simg
img2simg ./system.img ./system.simg
popd

