#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020 Arm Limited and affiliates.
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
readonly package=arm_opt_routines
# Pick a specific commit to make sure the confic we use is safe
# Note: we use a custom config to force use of GCC7 to avoid a
# bug with GCC9's default binutils
readonly version=433a3b1ff9b60f4baf7c30f2e1908b9629968a41
readonly src_host=https://github.com/ARM-software
readonly src_repo=optimized-routines

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version -b feature/gcc-7

export CFLAGS="-mcpu=native -O3"
export LDFLAGS="-lpthread"

install_dir=$PROD_DIR/$package 
cp ../config.mk config.mk

make -j $NP_MAKE all-math

mkdir -p $install_dir
cp -r ./build/lib $install_dir
