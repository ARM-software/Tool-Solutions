#!/bin/bash

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

source python3-venv/bin/activate
ck pull repo:ck-env
sudo apt-get -y install protobuf-compiler libprotoc-dev
cd $EXAMPLE_DIR/MLCommons
git clone https://github.com/mlcommons/inference.git --recursive
cd inference
git checkout r0.7
cd loadgen
CFLAGS="-std=c++14" python setup.py develop
cd ../vision/classification_and_detection
python setup.py develop

