#!/bin/bash

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

#
# Script to build Arm Compute Library for baremetal
#

# check tools and get the Arm CL
source ../build_armcl_bm.sh

cd ComputeLibrary/ 

# baremetal build, using armv7a for Cortex-R52 as there is no armv8r target yet
scons Werror=0 debug=1 neon=1 opencl=0 os=bare_metal arch=armv7a build=cross_compile cppthreads=0 openmp=0 standalone=1 -j $NPROC

cd ..

# build example
make

