#!/bin/bash -e

#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

DEVICE=$1
IMG_FOLDER=${PWD}

# partition table
sudo fastboot flash ptable ${IMG_FOLDER}/hisi-ptable.img

# bootloader
sudo fastboot flash xloader ${IMG_FOLDER}/hisi-sec_xloader.img
sudo fastboot flash fastboot ${IMG_FOLDER}/hisi-fastboot.img

# extra images
sudo fastboot flash nvme   ${IMG_FOLDER}/hisi-nvme.img
sudo fastboot flash fw_lpm3   ${IMG_FOLDER}/hisi-lpm3.img
sudo fastboot flash trustfirmware   ${IMG_FOLDER}/hisi-bl31.bin

# linux kernel and file system
sudo fastboot flash boot boot.img
sudo fastboot flash dts dts.img
sudo fastboot flash system system.simg

