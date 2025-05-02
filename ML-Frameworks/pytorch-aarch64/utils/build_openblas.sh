#!/bin/bash

# *******************************************************************************
# Copyright 2025 Arm Limited and affiliates.
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

# This script is based on the upstream PyTorch repository.
# Reference: pytorch/pytorch
# https://github.com/pytorch/pytorch/blob/main/.ci/docker/common/install_openblas.sh
# TODO: discard this and use `pytorch/.ci/docker/common/install_openblas.sh` to build OpenBLAS after version upgrade

source /common_utils/git-utils.sh

set -ex
OPENBLAS_HASH="9aa7a0b2a7b2770adec6ff26b34660d3bcd8c49c"
OPENBLAS_CHECKOUT_DIR="OpenBLAS"

cd /
git-shallow-clone https://github.com/OpenMathLib/OpenBLAS.git $OPENBLAS_HASH

OPENBLAS_BUILD_FLAGS="
NUM_THREADS=128
USE_OPENMP=1
NO_SHARED=0
DYNAMIC_ARCH=1
TARGET=ARMV8
CFLAGS=-O3
BUILD_BFLOAT16=1
"
make -j$(nproc) ${OPENBLAS_BUILD_FLAGS} -C ${OPENBLAS_CHECKOUT_DIR}
make -j$(nproc) ${OPENBLAS_BUILD_FLAGS} install -C ${OPENBLAS_CHECKOUT_DIR}
