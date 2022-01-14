#!/bin/bash
#
# build.sh - Build the SystemC Peripheral example
#
# Copyright 2015-2020 ARM Limited.
# All rights reserved.
#

arch=$(uname -m)

if [ "$arch" == 'aarch64' ]; then
    make rel_gcc63_64
else
    make rel_gcc73_64
fi

# select the version of gcc you use
#make rel_gcc49_64
#make rel_gcc64_64
#make rel_gcc73_64
#make rel_gcc93_64

