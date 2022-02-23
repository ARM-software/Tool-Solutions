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
  export USE_MKLDNN="ON"
  case $ONEDNN_BUILD in
    reference )
    ;;
    acl )
    export USE_MKLDNN_ACL="ON"
    ;;
  esac
fi

# Updating pytorch to use dnnl naming from oneDNN instead of mkldnn
patch -p1 < $PACKAGE_DIR/pytorch.patch

# Update the oneDNN tag in third_party/ideep
cd third_party/ideep/mkl-dnn
git checkout $ONEDNN_VERSION
# Do not add C++11 CMake CXX flag when building ACL and
# rename test_api to test_api_dnnl so it does not clash with PyTorch test_api
patch -p1 < $PACKAGE_DIR/onednn.patch

cd $PACKAGE_DIR/$src_repo

MAX_JOBS=${NP_MAKE:-$((num_cpus / 2))} PYTORCH_BUILD_VERSION=$TORCH_VERSION \
  PYTORCH_BUILD_NUMBER=1 OpenBLAS_HOME=$OPENBLAS_DIR BLAS="OpenBLAS" \
  CXX_FLAGS="$BASE_CFLAGS -O3 -mcpu=$CPU" LDFLAGS=$BASE_LDFLAGS USE_OPENMP=1 \
  USE_LAPACK=1 USE_CUDA=0 USE_FBGEMM=0 USE_DISTRIBUTED=0 python setup.py bdist_wheel

# Install the PyTorch python wheel via pip
pip install $(ls -tr dist/*.whl | tail)

# Move the whl into venv for easy extraction from container
mkdir -p $VENV_DIR/$package/wheel
mv $(ls -tr dist/*.whl | tail) $VENV_DIR/$package/wheel

# Check the installation was sucessfull
cd $HOME

# Check the wheel has installed ocrrectly.
# Note: only checks the major.minor version numbers, and not the point release
check_version=$(python -c 'import torch; print(torch.__version__)' | cut -f1,2 -d'.')
required_version=$(echo $version | cut -f1,2 -d'.')
if [[ "$check_version" == "$required_version" ]]; then
  echo "PyTorch $required_version package installed."
else
  echo "PyTorch package installation failed."
  exit 1
fi
