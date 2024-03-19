#!/bin/bash

# *******************************************************************************
# Copyright 2022,2024 Arm Limited and affiliates.
# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
readonly version=$TORCHDATA_VERSION
readonly src_host=https://github.com/pytorch
readonly src_repo=data
readonly num_cpus=$(nproc)

# Clone TorchData
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version
git submodule sync
git submodule update --init --recursive

# Building TorchData
CXX_FLAGS="${BASE_CFLAGS}" LD_FLAGS="${BASE_LDFLAGS}" FORCE_CUDA=0 python setup.py bdist_wheel

# Installing the TorchData python wheel via pip, dependencies are ignored as PyTorch is
# a dependency, which would cause it to overwrite the locally build PyTorch
pip install --no-deps $(ls -tr dist/*.whl | tail)
