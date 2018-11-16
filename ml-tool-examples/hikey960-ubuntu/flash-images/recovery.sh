#!/bin/bash -e

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

DEVICE=$1
IMG_FOLDER=${PWD}

if [ "${DEVICE}" == "" ]; then
	DEVICE=/dev/ttyUSB1
fi

sudo ./hikey_idt -c config -p ${DEVICE}
