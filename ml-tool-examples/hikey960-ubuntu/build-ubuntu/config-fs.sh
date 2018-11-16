#!/usr/bin/env bash

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

HOST=hikey960-1

# Set the machine’s hostname.
echo $HOST > "/etc/hostname"

# Create User
useradd -G sudo -m -s /bin/bash arm01
password=armml2018
echo -e "${password}\n${password}\n" | passwd arm01
cat >> /home/arm01/.bashrc <<"END_OF_FILE"
export LD_LIBRARY_PATH=$HOME/armnn-devenv/armnn/build
export LC_ALL=C
END_OF_FILE

mkdir /home/arm01/armnn-devenv
chown arm01 /home/arm01/armnn-devenv
chgrp arm01 /home/arm01/armnn-devenv

# Setup network
cat <<END_FILE > /etc/hosts
127.0.0.1   localhost.localdomain localhost $HOST
END_FILE

cat <<END_FILE > /etc/resolv.conf
nameserver 8.8.8.8
END_FILE

apt-get update

export DEBIAN_FRONTEND=noninteractive
echo "America/Los_Angeles" > "/etc/timezone"
dpkg-reconfigure -f noninteractive tzdata
apt-get install -y tzdata

# Get packages for networking
apt-get install -y net-tools
apt-get install -y netbase
apt-get install -y usbutils
apt-get install -y ethtool
apt-get install -y hostapd
apt-get install -y wpasupplicant
apt-get install -y wireless-tools
apt-get install -y busybox
apt-get install -y tightvncserver
apt-get install -y udhcpd
apt-get install -y sudo
apt-get install -y vim
apt-get install -y curl
apt-get install -y libtool
apt-get install -y valgrind
apt-get install -y autoconf
apt-get install -y unzip
apt-get install -y bzip2
apt-get install -y nano
apt-get install -y openssh-server
apt-get install -y network-manager
apt-get install -y iputils-ping
apt-get install -y clinfo
apt-get install -y module-init-tools
apt-get install -y g++
apt-get install -y git
apt-get install -y scons
apt-get install -y cmake
apt-get install -y aptitude software-properties-common python-software-properties
apt-get install -y avahi-daemon
apt-get install -y tmux screen htop
apt-get install -y libgomp1 libpng16-16

# GCC 6
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update
apt-get install -y gcc-6 g++-6
update-alternatives --quiet --skip-auto --force --install /usr/bin/gcc gcc /usr/bin/gcc-6 60 --slave /usr/bin/g++ g++ /usr/bin/g++-6    

apt-get install -y libblas-dev libgflags-dev libgoogle-glog-dev
apt-get install -y python-numpy python-dev python3
apt-get install -y libatlas-base-dev libatlas-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libsnappy-dev

apt-get install -y python3-pip
apt-get install -y python3-numpy
apt-get install -y python3-pil
apt-get install -y python3-matplotlib
apt-get install -y locales

# optional tensorflow
#curl -L https://github.com/lherman-cs/tensorflow-aarch64/releases/download/r1.4/tensorflow-1.4.0rc0-cp35-cp35m-linux_aarch64.whl > tensorflow-1.4.0rc0-cp35-cp35m-linux_aarch64.whl
#python3 -m pip install ./tensorflow-1.4.0rc0-cp35-cp35m-linux_aarch64.whl
#rm -f ./tensorflow-1.4.0rc0-cp35-cp35m-linux_aarch64.whl

# Update network interfaces
cat <<END_FILE >> /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)

# The loopback network interface
auto lo
iface lo inet loopback

END_FILE

mkdir /etc/OpenCL
mkdir /etc/OpenCL/vendors
echo "/usr/lib/aarch64-linux-gnu/mali-G71_r9p0_linux-arm64_1/fbdev/libOpenCL.so" > /etc/OpenCL/vendors/armocl.icd 

echo "KERNEL==\"mali0\", MODE=\"0666\"" > /etc/udev/rules.d/50-mali.rules

devices=( "/sys/devices/platform/e82c0000.mali/devfreq/e82c0000.mali/governor"
          "/sys/devices/platform/e82c0000.mali/devfreq/e82c0000.mali/device/power_policy"
          "/sys/devices/platform/e82c0000.mali/devfreq/e82c0000.mali/min_freq"
          "/sys/devices/platform/e82c0000.mali/devfreq/e82c0000.mali/max_freq" )
  for device in "${devices[@]}"
  do
    sed -i "13ichmod ugo+rw $device" /etc/rc.local
  done

sed -i "13i[ -x \"/usr/sbin/mali-link\" ] && /usr/sbin/mali-link" /etc/rc.local

# Enable serial console for login shell at serial ttyAMA6
cat <<END_FILE > /lib/systemd/system/getty.target.wants/getty-static.service
[Unit]
Description=getty on tty2-tty6 if dbus and logind are not available
ConditionPathExists=/dev/tty0
ConditionPathExists=!/lib/systemd/system/dbus.service
[Service]
Type=oneshot
ExecStart=/bin/systemctl --no-block start getty@tty2.service getty@tty3.service getty@tty4.service getty@tty5.service getty@tty6.service
RemainAfterExit=true
END_FILE

# Enable root to log on ttyAMA6
echo "ttyAMA6" >> "/etc/securetty"

