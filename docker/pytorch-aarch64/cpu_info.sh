#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2021 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************

############################################################0####################
# Functions to set correct target properties.
############################################################0####################

set -euo pipefail

# Return target name based on contents of /proc/cpuinfo
function get_cpu_info {
# Identify the CPU this is running on and set target arch to v8.2 for N1
CPU_IMPL=$(grep "CPU implementer" /proc/cpuinfo | tail -n1 | awk '{print $4}')
CPU_PART=$(grep "CPU part" /proc/cpuinfo | tail -n1 | awk '{print $4}')

local target="generic"

# Note: using 'case' rather than 'if' to facilitate addition of new CPU variants
case $CPU_IMPL in
  0x41) # Arm
    case $CPU_PART in
      0xd0c) # Neoverse N1
        target="neoverse-n1"
      ;;
      *)
      ;;
    esac
    ;;
  0x42|0x43) # Marvell
    case $CPU_PART in
      0x516|0x0af) # ThunderX2
        target="thunderx2t99"
      ;;
      *)
      ;;
    esac
  ;;
  *) # Default
  ;;
esac

echo $target

}

################################################################################
# Sets required -mtune, -mcou, -march flags for chosen target

function set_target {

  local target=

  if [[ $# != 0 ]]; then
    if [[ "$1" == "native" ]]; then
      target="$(get_cpu_info)"
    else
      target=$1
    fi
  fi

  echo "Setting target to $target"

  case $target in
    neoverse-n1 )
      cpu="neoverse-n1"
      tune="neoverse-n1"
      arch="armv8.2-a"
      blas_cpu="NEOVERSEN1"
      acl_arch="arm64-v8.2-a"
    ;;
    thunderx2t99 )
      cpu="thunderx2t99"
      tune="thunderx2t99"
      arch="armv8.1-a"
      blas_cpu="THUNDERX2T99"
      acl_arch="arm64-v8a"
    ;;
    generic )
      cpu="generic"
      tune="generic"
      arch="armv8-a"
      blas_cpu="ARMV8"
      acl_arch="arm64-v8a"
    ;;
    custom )
    # Update with custom settings
      cpu="neoverse-n1"
      tune="neoverse-n1"
      arch="armv8.2-a"
      blas_cpu="NEOVERSEN1"
      acl_arch="arm64-v8.2-a"
    ;;
    * )
      cpu="native"
      tune="native"
      arch="native"
      blas_cpu=
      acl_arch="arm64-v8a"
    ;;
 esac
echo "======================================"
echo "Building for target: $target"
echo "--------------------------------------"
echo " -mcpu                = $cpu"
echo " -mtune               = $tune"
echo " -march               = $arch"
echo " OpenBLAS target      = $blas_cpu"
echo " Compute Library arch = $acl_arch"
echo "======================================"
}
