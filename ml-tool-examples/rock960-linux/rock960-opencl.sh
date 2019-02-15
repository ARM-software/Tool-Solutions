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
packages="git locales dpkg-dev opencl-headers clinfo unzip bzip2 nano module-init-tools aptitude software-properties-common python-software-properties htop libblas-dev libgflags-dev libgoogle-glog-dev python-numpy python-dev python3 libatlas-base-dev libatlas-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libsnappy-dev python3-pip python3-numpy python3-pil python3-matplotlib locales"
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

