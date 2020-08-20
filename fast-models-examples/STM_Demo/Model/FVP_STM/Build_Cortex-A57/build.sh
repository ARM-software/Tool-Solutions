#!/bin/sh
# vim: syntax=sh

# brief  Build a CADI system using simgen
#
# Copyright ARM Limited 2020 All Rights Reserved.

simgen --num-comps-file 50 --gen-sysgen --warnings-as-errors -p "FVP_STM_Cortex-A57.sgproj" -b $*

# eof build.sh
