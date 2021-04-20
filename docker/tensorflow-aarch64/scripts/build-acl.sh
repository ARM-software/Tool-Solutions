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


set -euo pipefail

cd $PROD_DIR
readonly package=acl
readonly version=$ACL_VERSION
readonly src_host=https://review.mlplatform.org/ml
readonly src_repo=ComputeLibrary

mkdir -p $package
cd $package

# Clone ACL
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version

scons -j16 Werror=0 debug=0 neon=1 gles_compute=0 embed_kernels=0 os=linux arch=arm64-v8a build=native asserts=1
