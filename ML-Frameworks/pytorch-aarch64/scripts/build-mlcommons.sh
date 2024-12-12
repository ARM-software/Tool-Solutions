#!/bin/bash

# *******************************************************************************
# Copyright 2020-2023 Arm Limited and affiliates.
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

source python3-venv/bin/activate
ck pull repo:ck-env
sudo apt-get -y install protobuf-compiler libprotoc-dev

cd $EXAMPLE_DIR/MLCommons
git clone https://github.com/mlcommons/inference.git --recursive
cd inference
git checkout $ML_COMMONS_VERSION

patch -p1 < $MLCOMMONS_DIR/pytorch_native.patch
rm $MLCOMMONS_DIR/pytorch_native.patch


# Get updated openimages install script
git checkout $ML_COMMONS_VERSION -- vision/classification_and_detection/tools/openimages_mlperf.sh vision/classification_and_detection/tools/openimages.py

# Build loadgen
cd loadgen
CFLAGS="-std=c++14" python setup.py bdist_wheel
pip install dist/*.whl


# Build image classification and object detection benchmarks
cd $MLCOMMONS_DIR/inference/vision/classification_and_detection
python setup.py bdist_wheel
pip install dist/*.whl
# view method generates a runtime error where tensor is not
# contigious in memory. Using reshape avoids this.
sed -ie "s/\.view/\.reshape/g" python/models/ssd_r34.py

# Note: the BERT NLP benchmakrs are not built by default, due to the size
# of the datasets downloaded during the build. Uncomment the following
# lines to build the BERT benchmark by default.
#cd ../../language/bert
#make setup
