#!/bin/bash

set -e
set -u
set -o pipefail

# allow the script to be called from another location using an absolute path
mydir=$(dirname "$(realpath "$0")")

# Install python3.7
#py_pkgs=(python3.7 python3.7-dev python3.7-venv)
#if ! dpkg -s "${py_pkgs[@]}" > /dev/null 2>&1; then
#    sudo add-apt-repository ppa:deadsnakes/ppa -y
#    sudo apt-get update
#    sudo apt install "${py_pkgs[@]}" -y
#fi


# Install cmake 3.15 dependency to build driver
#wget -N https://github.com/Kitware/CMake/releases/download/v3.15.6/cmake-3.15.6-Linux-x86_64.sh
#mkdir cmake
#bash ./cmake-3.15.6-Linux-x86_64.sh --skip-license --exclude-subdir --prefix="$mydir/cmake"
#rm cmake-3.15.6-Linux-x86_64.sh

# Check is CMSIS repo is already cloned
# CMSIS repo location
CMSIS_DIR=./CMSIS_REPO
if [ ! -d "$mydir/CMSIS_REPO/CMSIS_5" ];
then
    mkdir $CMSIS_DIR
    pushd $CMSIS_DIR
    git clone -b develop https://github.com/ARM-software/CMSIS_5.git
    popd
else
    echo "CMSIS repo already cloned"
fi


# Install Ethos-U Drivers
core_driver="ethos-u-core-driver-20.11-rc1"
if [ ! -d "$core_driver" ]; then
    curl "https://git.mlplatform.org/ml/ethos-u/ethos-u-core-driver.git/snapshot/$core_driver.tar.gz" --output "$core_driver.tar.gz"
    tar xzvf "$core_driver.tar.gz"
    # Build the ethos-u55 driver
    mkdir -p ethos-u-core-driver-20.11-rc1/build && pushd "$_"
    # Run cmake
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=../../resources/toolchain/armclang.cmake \
        -DCMAKE_SYSTEM_PROCESSOR=cortex-m55 \
        -DCMAKE_CXX_COMPILER=armclang \
        -DCMSIS_PATH=../../CMSIS_REPO/CMSIS_5 \
        -DDRIVER_LOG_SUPPORT=1 
    # Build
    make
    popd
else
    echo "Driver already present"
fi


# Clone the tensorflow git repo if you haven't already
if [ ! -d "tensorflow" ]; then
#    aws s3 cp s3://arm-tool-solutions/Sesame/tensorflow_20200702.tar.gz .
    tar xzvf tensorflow_20200702.tar.gz
else
    echo "Tensorflow already present"
fi

# Copy the files to the right locations
cp -r "$mydir/resources/TFLite_micro_FVP_Support/test_runner_test.cc" "$mydir/tensorflow/tensorflow/lite/micro/examples/test_runner/test_runner_test.cc"
cp -r "$mydir/resources/TFLite_micro_FVP_Support/fvp"* "$mydir/tensorflow/tensorflow/lite/micro/tools/make/targets/"


