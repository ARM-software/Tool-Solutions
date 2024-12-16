#!/usr/bin/env bash

# ******************************************************************************
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
# ******************************************************************************

set -euo pipefail

git clone https://github.com/mlcommons/inference_results_v0.7.git
cd inference_results_v0.7
# patching for loadgen, boost, opencv and tf paths
patch -p1 < ../Makefile.patch
# patching loadrun and netrun cpp
patch -p1 < ../servermode.patch

cd closed/Intel/code/resnet/resnet-tf/loadrun
make -C ../backend clean
make -C ../backend
make clean
make
chmod a+x ./*.sh
