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
readonly package=openblas
readonly version=$OPENBLAS_VERSION
readonly src_host="https://github.com/OpenMathLib"
readonly src_repo="OpenBLAS"

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

install_dir=$PROD_DIR/$package

export CFLAGS="-O3"
extra_args="USE_OPENMP=1"
[[ ${BLAS_CPU} ]] && extra_args="$extra_args TARGET=${blas_cpu}"
[[ ${BLAS_NCORES} ]] && extra_args="$extra_args NUM_THREADS=${blas_ncores}"

make -j $NP_MAKE $extra_args
make -j $NP_MAKE $extra_args PREFIX=$install_dir install
