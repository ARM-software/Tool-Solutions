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

cd $PACKAGE_DIR
readonly version=$TF_VERSION
readonly src_host=https://github.com/tensorflow
readonly src_repo=tensorflow
readonly dst_repo=tensorflow_src
readonly num_cpus=$(grep -c ^processor /proc/cpuinfo)

# Clone tensorflow, build it and build benchmark_model binary
git clone ${src_host}/${src_repo}.git ${dst_repo}
cd ${dst_repo}
git checkout tags/v${version}

echo 'Using the latest commit for XNNPACK fetch'
patch -p1 < ../tflite.patch

cd ..

mkdir tflite_build
cd tflite_build

cmake ../${dst_repo}/tensorflow/lite -DTFLITE_ENABLE_RUY=ON
cmake --build . -j ${num_cpus}

cmake --build . -j ${num_cpus} -t benchmark_model
