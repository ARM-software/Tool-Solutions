#!/bin/bash

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

source python3-venv/bin/activate
pip install cython
pip install absl-py pillow pycocotools
pip install ck
ck pull repo:ck-env
pip install scikit-build
sudo apt-get -y install protobuf-compiler libprotoc-dev
git clone https://github.com/mlcommons/inference.git --recursive
cd inference
git checkout master
# Scripts to support running of MLPerf in different modes. Refer to README.md for details.
patch -p1 < ../optional-mlcommons-changes.patch
cd loadgen
CFLAGS="-std=c++14" python setup.py develop
cd ../vision/classification_and_detection
python setup.py develop
