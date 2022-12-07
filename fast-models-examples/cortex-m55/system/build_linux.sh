#!/bin/sh
#
# build.sh - Build the Cortex-M55 example.
#
# Copyright 2015 ARM Limited.
# All rights reserved.
#

GCC=`gcc -dumpversion 2> /dev/null |  sed -e "s/\([0-9]*\.[0-9]*\)\.[0-9]*/\1/" | sed 's/\.[0-9]//'`
GCC2=`gcc -dumpversion 2> /dev/null`

case "$GCC" in 
    9 ) make rel_gcc93_64 ; break ;;
    7 ) make rel_gcc73_64 ; break ;;
    6 ) make rel_gcc64_64 ; break ;;
    4 ) make rel_gcc49_64 ; break ;;
    * ) echo "unsupported gcc ($GCC2). gcc 4.9, 6.4 and 7.3 are supported" ; break ;;
esac
