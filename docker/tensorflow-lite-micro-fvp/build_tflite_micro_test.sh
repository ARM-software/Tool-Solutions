#!/bin/bash
#
# Copyright 2019 ARM Limited.
# All rights reserved.
#

# Script to build TFLite-micro Test applications for M7 

usage() {
    echo "Usage: $0 [-t cpu-target] builds application for cpu specified valid options (m7, m55)" 1>&2 
    echo "          [-u tflite-micro-example] build selected tflite-micro example for selected cpu target. Valid options (magic_wand, micro_speech)" 1>&2
    echo "          [-h --help] prints help message " 1>&2
    exit 1
}


# allow the script to be called from another location using an absolute path
mydir="$(dirname $0)"

# Location of CMSIS
CMSIS_DIR=$mydir/../CMSIS_REPO/CMSIS_5


#Process command line arguments
OPTS=`getopt -o t:u:h --long cpu-target:,tflite-micro-example:,help -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Error: failed to parse options" >&2 ; exit 1 ; fi

eval set -- "$OPTS"

APP=""
CPU=""

while true; do
    case "$1" in
	-t | --cpu-target) CPU="$2" ; shift 2 ;;
	-u | --tflite-micro-example) APP="$2" ; shift 2 ;;
	-h | --help ) usage ; shift ;;
	-- ) shift; break ;;
	* ) break ;;
    esac
done
     

# Location of software programs
SW=~/Cortex-"$CPU"/software/exe
mkdir -p $SW

# Build the make files for the tflite-micro example selected
cd tensorflow/
make -f tensorflow/lite/micro/tools/make/Makefile TARGET=fvp TARGET_ARCH=cortex-$CPU TAGS="armclang cmsis-nn" CMSIS_PATH=$CMSIS_DIR generate_"$APP"_test_make_project

pushd tensorflow/lite/micro/tools/make/gen/fvp_cortex-$CPU/prj/"$APP"_test/make
make -j16

fromelf --bin --bincombined --output="$APP"_test.bin "$APP"_test
fromelf -c  "$APP"_test > "$APP"_test.dis
cp -r "$APP"_test $SW/
cp -r "$APP"_test.dis $SW/

popd

