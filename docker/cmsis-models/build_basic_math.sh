#!/bin/bash
#
# Copyright 2020 ARM Limited.
# All rights reserved.
#

# Script to build CMSIS-DSP Test applications for Cortex-M55 and Cortex-M7F

usage() {
    echo "Usage: $0 [-t cpu-target] builds application for cpu specified valid options (M7F, M55)" 1>&2
    echo "          [-d --datatype] group of tests for specified data type valid options (Q7, Q15, Q31, F32) " 1>&2
    echo "          [-i --id] test id in group of tests selected " 1>&2
    echo "          [-h --help] prints help message " 1>&2
    exit 1
}


# allow the script to be called from another location using an absolute path
mydir="$(dirname $0)"

# Location of CMSIS-DSP Test directory
TESTDIR=$mydir/CMSIS_5/CMSIS/DSP/Testing/

#Process command line arguments
OPTS=`getopt -o t:d:i:h --long cpu-target:,datatype:,id:,help -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Error: failed to parse options" >&2 ; exit 1 ; fi

eval set -- "$OPTS"

CPU=""
DATATYPE=""
TESTID=""

while true; do
    case "$1" in
	-t | --cpu-target) CPU="$2" ; shift 2 ;;
	-d | --datatype ) DATATYPE="$2" ; shift 2;;
	-i | --testid ) TESTID="$2" ; shift 2;;
	-h | --help ) usage ; shift ;;
	-- ) shift; break ;;
	* ) break ;;
    esac
done

# CPU types: M7F or M55
if [ "$CPU" = "M7F" ]; then
    echo "Building for Cortex-M7F target"
elif [ "$CPU" = "M55" ]; then
    echo "Building for Cortex-M55 target"
else
    echo "Unknown CPU target: $CPU"
    exit 1
fi

# Data types: Q7, Q15, Q31, F32
if [ "$DATATYPE" = "Q7" ]; then
    echo " Building BasicMathsBenchmarks for 8-bit integer types"
elif [ "$DATATYPE" = "Q15" ]; then
    echo "Building BasicMathsBenchmarks for 16-bit integer types"
elif [ "$DATATYPE" = "Q31" ]; then
    echo "Building BasicMathsBenchmarks for 32-bit integer types"
elif [ "$DATATYPE" = "F32" ]; then
    echo "Building BasicMathsBenchmarks for 32-bit floating-point types"
else
    echo "Unknown Data Type: $DATATYPE"
    exit 1
fi
     

# move into the test directory
pushd $TESTDIR

if [ -f Output.pickle ]; then
    rm Output.pickle
    echo "Deleting the existing Output.pickle"
fi


python3 PatternGeneration/BasicMaths.py
python3 preprocess.py -f bench.txt
./createDefaultFolder.sh
python3 processTests.py -e
python3 processTests.py -e BasicMathsBenchmarks"$DATATYPE"
python3 processTests.py -e BasicMathsBenchmarks"$DATATYPE" "$TESTID"
mkdir build_"$CPU"_"$DATATYPE"
cp -r cmake_"$CPU".sh build_"$CPU"_"$DATATYPE"
cd build_"$CPU"_"$DATATYPE"
./cmake_"$CPU".sh

NPROC=`grep -c ^processor /proc/cpuinfo`
make -j $NPROC

# all done
popd

