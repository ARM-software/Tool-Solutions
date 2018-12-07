#!/bin/bash

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

#
# Script to build all of the required software for the Arm NN examples
#

function IsPackageInstalled() {
    dpkg -s "$1" > /dev/null 2>&1
}


# save history to logfile
exec > >(tee -i logfile)
exec 2>&1

echo "Building Arm NN in $HOME/armnn-devenv"

# Start from home directory
cd $HOME 

# if nothing, found make a new diectory
[ -d armnn-devenv ] || mkdir armnn-devenv


# check for previous installation, HiKey 960 is done as a mount point so don't 
# delete all from top level, drop down 1 level
while [ -d armnn-devenv/pkg ]; do
    read -p "Do you wish to remove the existing armnn-devenv build environment? " yn
    case $yn in
        [Yy]*) rm -rf armnn-devenv/pkg armnn-devenv/ComputeLibrary armnn-devenv/armnn armnn-devenv/gator ; break ;;
        [Nn]*) echo "Exiting " ; exit;;
        *) echo "Please answer yes or no.";;
    esac
done

cd armnn-devenv 

# packages to install on the host
packages="wget curl autoconf autogen libtool scons cmake g++"
for package in $packages; do
    if ! IsPackageInstalled $package; then
        sudo apt-get install -y $package
    fi
done

# number of CPUs for make -j
NPROC=`grep -c ^processor /proc/cpuinfo`

# Boost

mkdir -p pkg/boost 
echo "building boost"
pushd pkg/boost

wget https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.bz2
tar xf boost_1_64_0.tar.bz2
cd boost_1_64_0
./bootstrap.sh --prefix=$HOME/armnn-devenv/pkg/boost/install
./b2 install link=static cxxflags=-fPIC  --with-filesystem --with-test --with-log --with-program_options --prefix=$HOME/armnn-devenv/pkg/boost/install 

popd

# gator
git clone https://github.com/ARM-software/gator.git
make -C gator/daemon -j $NPROC
cp gator/daemon/gatord $HOME/

# Arm Compute Library 
# Pick either official version from github or annotated version for Streamline

# official version
#git clone https://github.com/ARM-software/ComputeLibrary.git

# version with Streamline annotations
git clone https://github.com/jasonrandrews/ComputeLibrary.git

echo "building Arm CL"
pushd ComputeLibrary

# check gcc version in case adjustments are needed based on compiler
VER=`gcc -dumpversion | awk 'BEGIN{FS="."} {print $1}'`
echo "gcc version is $VER"

# check for Mali device node
[ -c /dev/mali? ] && OpenCL=1 || OpenCL=0 

# check for Armv8 or Armv7
Arch=`uname -m`
if [ $Arch = "armv7l" ]; then
    CLarch=armv7a
else
    CLarch=arm64-v8a
fi

scons arch=$CLarch neon=1 opencl=$OpenCL embed_kernels=$OpenCL Werror=0 \
  extra_cxx_flags="-fPIC" benchmark_tests=0 examples=0 validation_tests=0 \
  os=linux gator_dir="$HOME/armnn-devenv/gator" -j $NPROC

popd

# TensorFlow and Google protobuf
# Latest TensorFlow had a problem, udpate branch as needed

pushd pkg
mkdir install
git clone --branch 3.5.x https://github.com/protocolbuffers/protobuf.git
git clone https://github.com/tensorflow/tensorflow.git

# build Protobuf
cd protobuf
./autogen.sh
mkdir build ; cd build
../configure --prefix=$HOME/armnn-devenv/pkg/install 
make -j $NPROC
make install 

popd

# Arm NN
# Pick either official version from github or annotated version for Streamline

# official version
#git clone https://github.com/ARM-software/armnn.git
# version with Streamline annotations
git clone https://github.com/jasonrandrews/armnn.git

pushd pkg/tensorflow/

$HOME/armnn-devenv/armnn/scripts/generate_tensorflow_protobuf.sh $HOME/armnn-devenv/pkg/tensorflow-protobuf $HOME/armnn-devenv/pkg/install

popd

# Arm NN
pushd armnn
mkdir build ; cd build

cmake ..  \
-DARMCOMPUTE_ROOT=$HOME/armnn-devenv/ComputeLibrary/ \
-DARMCOMPUTE_BUILD_DIR=$HOME/armnn-devenv/ComputeLibrary/build \
-DBOOST_ROOT=$HOME/armnn-devenv/pkg/boost/install/ \
-DTF_GENERATED_SOURCES=$HOME/armnn-devenv/pkg/tensorflow-protobuf/  \
-DBUILD_TF_PARSER=1 \
-DPROTOBUF_ROOT=$HOME/armnn-devenv/pkg/install   \
-DPROTOBUF_INCLUDE_DIRS=$HOME/armnn-devenv/pkg/install/include   \
-DPROFILING_BACKEND_STREAMLINE=1 \
-DGATOR_ROOT=$HOME/armnn-devenv/gator \
-DARMCOMPUTENEON=1  \
-DARMCOMPUTECL=$OpenCL \
-DPROTOBUF_LIBRARY_DEBUG=$HOME/armnn-devenv/pkg/install/lib/libprotobuf.so \
-DPROTOBUF_LIBRARY_RELEASE=$HOME/armnn-devenv/pkg/install/lib/libprotobuf.so \
-DCMAKE_CXX_FLAGS="-Wno-error=sign-conversion" \
-DCMAKE_BUILD_TYPE=Debug

if [ $Arch = "armv7l" ]; then
    # avoid running out of memory on armv7 systems 
    make
else
    make -j $NPROC
fi
popd

echo "done, everything in armnn-devenv/"
cd ..

