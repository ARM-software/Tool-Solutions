
#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

#
# Script to build Arm Compute Library for baremetal
#

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "This file is sourced by the examples, don't run it"
    exit 1
fi

function in_path {
  builtin type -P "$1" &> /dev/null
}

# number of CPUs for make -j
NPROC=`grep -c ^processor /proc/cpuinfo`

# an argument can be used to change the compiler name
# this is for checking purposes only, compiler is set during the Arm CL build
if [ "$#" -eq 1 ]; then
    COMPILER=$1
else
    COMPILER=arm-eabi-g++
fi

# try to catch any missing tools before starting the build
tools_to_check="git scons $COMPILER"
for tool in $tools_to_check; do
    echo "checking $tool"
    if ! in_path $tool; then
        echo "error: $tool is not avilable, please install or add to PATH and try again"
        exit
    fi
done

# check for previous build and delete if needed
if [ -d ComputeLibrary ]; then
    read -p "Do you wish to remove the existing ComputeLibrary/ build? " yn
    case $yn in
        [Yy]*) rm -rf ComputeLibrary/ ; break ;;
        [Nn]*) echo "Continue with existing directory... " ;;
        *) echo "Please answer yes or no.";;
    esac
fi

# get the Arm Compute Library
git clone https://github.com/ARM-software/ComputeLibrary.git

