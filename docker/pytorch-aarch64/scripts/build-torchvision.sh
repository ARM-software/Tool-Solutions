#!/bin/bash

# *******************************************************************************
# Copyright 2023 Arm Limited and affiliates.
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

set -euo pipefail

cd $PACKAGE_DIR
readonly version=$TORCHVISION_VERSION
readonly src_host=https://github.com/pytorch
readonly src_repo=vision
readonly num_cpus=$(nproc)

# Clone TorchVision
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version
git submodule sync
git submodule update --init --recursive

# Support for fixed format kernels
patch -p1 < $PACKAGE_DIR/torchvision.patch
rm $PACKAGE_DIR/torchvision.patch

# Building TorchVision
CXX_FLAGS="${BASE_CFLAGS}" LD_FLAGS="${BASE_LDFLAGS}" FORCE_CUDA=0 python setup.py bdist_wheel

# Installing the TorchVision python wheel via pip, dependencies are ignored as PyTorch is
# a dependency, which would cause it to overwrite the locally build PyTorch
pip install --no-deps $(ls -tr dist/*.whl | tail)
