#!/bin/bash
#
# run.sh - Run the EVS_DualCore example.
#
# Copyright 2020 ARM Limited.
# All rights reserved.
#

axf0=../Software/startup_Cortex-M0+_AC6_sharedmem/startup_Cortex-M0+_AC6.axf
axf4=../Software/startup_Cortex-M4_AC6_sharedmem/startup_Cortex-M4_AC6.axf

if [ ! -e ${axf0} ]; then
    echo "ERROR: ${axf0}: application not found"
    echo "Build the Cortex-M0+ application in the software folder before running this example"
    exit 1
fi

if [ ! -e ${axf4} ]; then
    echo "ERROR: ${axf4}: application not found"
    echo "Build the Cortex-M4 application in the software folder before running this example"
    exit 1
fi

./EVS_Cortex-M0Plus-M4.x -a Cortex_M4.Core=${axf4} -a Cortex_M0Plus.Core=${axf0} --stat --cyclelimit 10000000

