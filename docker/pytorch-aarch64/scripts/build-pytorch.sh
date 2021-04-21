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

if [[ $ONEDNN_BUILD ]]; then
  # Patch to enable oneDNN (MKL-DNN).
  patch -p1 < $PACKAGE_DIR/pytorch_onednn.patch
  export USE_MKLDNN="ON"

  case $ONEDNN_BUILD in
    reference )
    ;;
    acl )
    export USE_MKLDNN_ACL="ON"
    ;;
  esac
fi

# Update the oneDNN tag in third_party/ideep
cd third_party/ideep/mkl-dnn
git checkout $ONEDNN_VERSION

cd $PACKAGE_DIR/$src_repo

MAX_JOBS=${NP_MAKE:-$((num_cpus / 2))} OpenBLAS_HOME=$OPENBLAS_DIR/lib CXX_FLAGS="$BASE_CFLAGS -O3" LDFLAGS=$BASE_LDFLAGS USE_OPENMP=1 USE_LAPACK=1 USE_CUDA=0 USE_FBGEMM=0 USE_DISTRIBUTED=0 python setup.py install

# Check the installation was sucessful
cd $HOME

# Check the wheel has installed correctly.
# Note: only checks the major.minor version numbers, and not the point release
check_version=$(python -c 'import torch; print(torch.__version__)' | cut -f1,2 -d'.')
required_version=$(echo $version | cut -f1,2 -d'.')
if [[ "$check_version" == "$required_version" ]]; then
  echo "PyTorch $required_version package installed."
else
  echo "PyTorch package installation failed."
  exit 1
fi
