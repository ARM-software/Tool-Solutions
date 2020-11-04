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
readonly package=pytorch
readonly version=$TORCH_VERSION
readonly src_host=https://github.com/pytorch
readonly src_repo=pytorch
readonly num_cpus=$(grep -c ^processor /proc/cpuinfo)

# Clone PyTorch
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version
git submodule sync
git submodule update --init --recursive

# Patch to avoid using asm not supported for GCC builds.
curl https://patch-diff.githubusercontent.com/raw/pytorch/pytorch/pull/35157.patch | patch -p1

if [[ $ONEDNN_BUILD ]]; then
  # Patch to enable oneDNN (MKL-DNN).
  patch -p1 < $PACKAGE_DIR/pytorch_onednn.patch
  export USE_MKLDNN="ON"

  case $ONEDNN_BUILD in
    reference )
    ;;
    acl )
    export USE_ACL="ON"
    ;;
  esac

fi

# Update the oneDNN tag in third_party/ideep
cd third_party/ideep/mkl-dnn
git checkout $ONEDNN_VERSION
patch -p1 < $PACKAGE_DIR/onednn_acl_verbose.patch

cd $PACKAGE_DIR/$src_repo

MAX_JOBS=${NP_MAKE:-$((num_cpus / 2))} OpenBLAS_HOME=$OPENBLAS_DIR/lib CXX_FLAGS="$BASE_CFLAGS -O3" LDFLAGS=$BASE_LDFLAGS USE_OPENMP=1 USE_LAPACK=1 USE_CUDA=0 USE_FBGEMM=0 USE_DISTRIBUTED=0 python setup.py install

# Check the installation was sucessfull
cd $HOME
python -c 'import torch; print(torch.__version__)' > version.log
if grep $version version.log; then
  echo "PyTorch $TORCH_VERSION package installed."
else
  echo "PyTorch package installation failed."
  exit 1
fi
rm $HOME/version.log
