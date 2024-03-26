#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020-2024 Arm Limited and affiliates.
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
readonly num_cpus=$(nproc)

install_dir=$PROD_DIR/$package

# Clone oneDNN
[[ ! -d ${src_repo} ]] && git clone ${src_host}/${src_repo}.git
cd ${src_repo}

git checkout $version

patch -p1 < ../acl_dynamic_quantization.patch
patch -p1 < ../acl_in_place_sum.patch

wget https://review.mlplatform.org/changes/ml%2FComputeLibrary\~11169/revisions/3/patch\?zip -O acl_bf16bf16_matmul.patch.zip && unzip acl_bf16bf16_matmul.patch.zip
sed "5233,5279d" abd3394.diff > tmp.patch
cat tmp.patch ../acl_bf16_dispatch.patch > acl_bf16bf16_matmul.patch
patch -p1 < acl_bf16bf16_matmul.patch

patch -p1 < ../acl_parallelize_im2col.patch

wget https://review.mlplatform.org/changes/ml%2FComputeLibrary~11354/revisions/2/patch?zip -O acl_a64_ffhybrid_fp32bf16fp32_mmla_6x16.patch.zip && unzip acl_a64_ffhybrid_fp32bf16fp32_mmla_6x16.patch.zip
mv 7d9cc43.diff acl_a64_ffhybrid_fp32bf16fp32_mmla_6x16.patch
patch -p1 < acl_a64_ffhybrid_fp32bf16fp32_mmla_6x16.patch

# Default to v8a if $acl_arch is unset.
arch=${ACL_ARCH:-"arm64-v8a"}
echo "Compute Library arch = ${arch}"

multi_isa=0

[[ "$arch" == "armv8.2-a" ]] || [[ "$arch" == "armv8a" ]] && multi_isa=1

# Build with scons
scons -j${NP_MAKE:-$((num_cpus / 2))}  Werror=0 debug=0 neon=1 opencl=0 embed_kernels=0 \
  os=linux arch=$arch build=native multi_isa=$multi_isa \
  fixed_format_kernels=1 openmp=1 cppthreads=0 \
  build_dir=$install_dir/build

cp -r arm_compute $install_dir
cp -r src $install_dir
cp -r include $install_dir
cp -r utils $install_dir
cp -r support $install_dir
