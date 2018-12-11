#!/bin/bash

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

#
# Script to add OpenCL to Rock 960 for Ubuntu or Debian 
# Run it after the first boot to add the OpenCL driver
#

function IsPackageInstalled() {
    dpkg -s "$1" > /dev/null 2>&1
}

sudo apt-get update && sudo apt-get upgrade -y

# packages to install
packages="git locales dpkg-dev opencl-headers clinfo"
for package in $packages; do
    if ! IsPackageInstalled $package; then
        sudo apt-get install -y $package
    fi
done

pushd $HOME

[ -d libmali ] || git clone https://www.github.com/rockchip-linux/libmali

cd libmali

tuple=`dpkg-architecture -qDEB_HOST_MULTIARCH`
echo "multiarch tuple is $tuple"

sudo rm -f /usr/lib/$tuple/libOpenCL.so
sudo cp -p lib/$tuple/libmali-midgard-t86x-r14p0-wayland.so  /usr/lib/$tuple/
cd /usr/lib/$tuple/
sudo ln -s libmali-midgard-t86x-r14p0-wayland.so libOpenCL.so

[ -d /etc/OpenCL/vendors ] || sudo mkdir -p /etc/OpenCL/vendors
sudo rm -f /etc/OpenCL/vendors/mali.icd
echo "/usr/lib/$tuple/libOpenCL.so" | sudo tee --append /etc/OpenCL/vendors/mali.icd

popd

[ -x /usr/bin/clinfo ] && clinfo || echo "cannot find clinfo"

echo "OpenCL support is added"

