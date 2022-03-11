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

cd $PACKAGE_DIR

git clone https://review.mlplatform.org/ml/ComputeLibrary
cd ComputeLibrary/
git checkout tags/v22.02 -b v22.02

readonly num_cpus=$(grep -c ^processor /proc/cpuinfo)
scons -j ${num_cpus} arch=armv8.2-a build=native os=linux neon=1 extra_cxx_flags="-fPIC" benchmark_tests=0 validation_tests=0 multi_isa=1
