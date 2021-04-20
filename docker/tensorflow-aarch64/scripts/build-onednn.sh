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

if [[ $ONEDNN_BUILD == 'armpl' || $ONEDNN_BUILD == 'openblas' ]]; then
  exit 0
fi

cd $PACKAGE_DIR
readonly package=onednn
readonly version=$ONEDNN_VERSION
readonly tf_id=$TF_VERSION_ID
readonly src_host=https://github.com/oneapi-src
readonly src_repo=oneDNN

# Clone oneDNN
echo "oneDNN VERSION" $version
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version

# Apply patch to add AArch64 flags, and OpenBLAS lib
if [[ $tf_id == '1' ]]; then
  # This patch is for version 0.21.3
  patch -p1 <../mkldnn.patch
elif [[ $tf_id == '2' ]]; then
  # This patch is for version 1.4+
  patch -p1 < ../oneDNN.patch
else
  echo 'Invalid TensorFlow version when applying patches to the oneDNN repository'
  exit 1
fi

cmake_options="-DCMAKE_BUILD_TYPE=release \
  -DDNNL_CPU_RUNTIME=OMP \
  -DCMAKE_INSTALL_PREFIX=$PROD_DIR/$package/release"

cxx_flags="${BASE_CFLAGS} -O3"
blas_flags=""
blas_libs=""

cmake_options="$cmake_options -DCMAKE_CXX_STANDARD=14 -DCMAKE_CXX_EXTENSIONS=OFF"
if [[ $ONEDNN_BUILD == 'acl' ]]; then cmake_options="$cmake_options -DDNNL_AARCH64_USE_ACL=ON -DDNNL_AARCH64=ON"; fi

echo "CMake options: $cmake_options"
echo "Compiler flags: $cxx_flags"
echo "BLAS flags: $blas_libs $blas_flags"

mkdir -p build
cd build

# TODO: Update the BLAS selection options to use
# FindBLAS.cmake.
# From oneDNN v1.6 onwards, OpenBLAS and ArmPL
# BLAS libraries can be selected using the
# -DDNNL_BLAS_VENDOR=OPENBLAS / ARMPL cmake option
# Subsequent releases will support the free-of-charge
# version of ArmPL.
APPEND_SHARED_LIBS="$blas_libs" CXXFLAGS="$cxx_flags $blas_flags" \
  cmake ../. $cmake_options

make -j $NP_MAKE VERBOSE=1
make install
