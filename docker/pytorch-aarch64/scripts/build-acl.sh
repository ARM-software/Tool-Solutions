#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020-2021 Arm Limited and affiliates.
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
readonly package=ComputeLibrary
readonly version=$ACL_VERSION
readonly src_host=https://review.mlplatform.org/ml
readonly src_repo=ComputeLibrary

install_dir=$PROD_DIR/$package

# Clone oneDNN
[[ ! -d ${src_repo} ]] && git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version

# Default to v8a if $acl_arch is unset.
arch=${ACL_ARCH:-"arm64-v8a"}
echo "Compute Library arch = ${arch}"

# Build with scons
scons -j16  Werror=0 debug=0 neon=1 gles_compute=0 embed_kernels=0 \
  os=linux arch=$arch build=native \
  build_dir=$install_dir/build

cp -r arm_compute $install_dir
cp -r include $install_dir
cp -r utils $install_dir
cp -r support $install_dir
