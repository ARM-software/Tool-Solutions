#!/bin/bash
#
# Copyright 2019 ARM Limited.
# All rights reserved.
#

# Script to build TFLite-micro Test applications for M55 

usage() {
    echo "Usage: $0 [-t tflite-micro-example] build selected tflite-micro example for M55 target. Valid options (hello_world, magic_wand, micro_speech, network_tester, person_detection)" 1>&2
    echo "          [-h --help] prints help message " 1>&2
    exit 1
}


# allow the script to be called from another location using an absolute path
mydir="$(dirname $0)"

# Location of CMSIS
CMSIS_DIR=$mydir/../CMSIS_REPO/cmsis

#Currently only CPU supported is M55
CPU=M55

#Process command line arguments
OPTS=`getopt -o t:h --long tflite-micro-example:,help -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Error: failed to parse options" >&2 ; exit 1 ; fi

eval set -- "$OPTS"

APP=""

while true; do
    case "$1" in
	-t | --tflite-micro-example) APP="$2" ; shift 2 ;;
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
make -f tensorflow/lite/micro/tools/make/Makefile TARGET=ipss TARGET_ARCH=cortex-m55 TAGS="armclang cmsis-nn" CMSIS_PATH=$CMSIS_DIR generate_"$APP"_test_make_project

pushd tensorflow/lite/micro/tools/make/gen/ipss_cortex-m55/prj/"$APP"_test/make
make -j8 

fromelf --bin --bincombined --output="$APP"_test.bin "$APP"_test
fromelf -c  "$APP"_test > "$APP"_test.dis
cp -r "$APP"_test $SW/
cp -r "$APP"_test.dis $SW/

popd

