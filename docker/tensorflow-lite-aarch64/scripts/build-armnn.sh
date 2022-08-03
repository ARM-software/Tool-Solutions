#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2021-2022 Arm Limited and affiliates.
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

readonly num_cpus=$(nproc)

cd $PACKAGE_DIR

wget -O flatbuffers-1.12.0.tar.gz https://github.com/google/flatbuffers/archive/v1.12.0.tar.gz
tar xf flatbuffers-1.12.0.tar.gz
cd flatbuffers-1.12.0
# Apply patch not to error with new GCC versions
patch -p1 < ../flatbuffers.patch
mkdir build && cd build
CXXFLAGS="-fPIC" cmake .. -DFLATBUFFERS_BUILD_FLATC=1 -DCMAKE_INSTALL_PREFIX:PATH=$PACKAGE_DIR/flatbuffers
make -j ${num_cpus}
make install

cd $PACKAGE_DIR
git clone https://review.mlplatform.org/ml/armnn
cd armnn
git checkout tags/v22.02 -b v22.02
patch -p1 < ../armnn.patch
mkdir build && cd build
cmake .. -DARMCOMPUTE_ROOT=$PACKAGE_DIR/ComputeLibrary -DARMCOMPUTE_BUILD_DIR=$PACKAGE_DIR/ComputeLibrary/build -DBUILD_TF_LITE_PARSER=1 -DTF_LITE_GENERATED_PATH=$PACKAGE_DIR/tensorflow_src/tensorflow/lite/schema -DFLATBUFFERS_ROOT=$PACKAGE_DIR/flatbuffers -DFLATC_DIR=$PACKAGE_DIR/flatbuffers-1.12.0/build -DARMCOMPUTENEON=1 -DARMNNREF=1 -DBUILD_TESTS=1 -DBUILD_ARMNN_TFLITE_DELEGATE=1 -DTENSORFLOW_ROOT=$PACKAGE_DIR/tensorflow_src -DTFLITE_LIB_ROOT=$PACKAGE_DIR/tflite_build -DFLATBUFFERS_ROOT=$PACKAGE_DIR/flatbuffers
make -j ${num_cpus}
