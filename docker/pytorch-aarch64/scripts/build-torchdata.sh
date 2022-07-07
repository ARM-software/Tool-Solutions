#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2022 Arm Limited and affiliates.
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
readonly package=torchdata
readonly version=$TORCHDATA_VERSION
readonly src_host=https://github.com/pytorch
readonly src_repo=data
readonly cppflags="-I$VENV_PACKAGE_DIR/pybind11/include"

# Clone Torchdata
git clone ${src_host}/${src_repo}.git ${package}
cd ${package}
git checkout v$version -b v$version
git submodule sync
git submodule update --init --recursive

# Run Python build script
CPPFLAGS=$cppflags python setup.py clean install
