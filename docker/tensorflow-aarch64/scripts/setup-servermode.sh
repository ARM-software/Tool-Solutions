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

# This script is for downloading the model and dataset specfically for ResNet50 server-mode

ck pull repo:ck-env
# resnet50
wget https://zenodo.org/record/2535873/files/resnet50_v1.pb

# Run optimized library pass
python -m tensorflow.python.tools.optimize_for_inference --input resnet50_v1.pb --output resnet50v1fp32_optimized.pb --input_names=input_tensor --output_names=ArgMax

# Select option 1: val-min data set. Issue when downloading the complete val data set using ck-env [https://github.com/ctuning/ck-env/issues/101]
ck install package --tags=image-classification,dataset,imagenet,aux
echo 1 | ck install package --tags=image-classification,dataset,imagenet,val

# Copy the labels into the image location
cp ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-aux/val.txt ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min/val_map.txt
