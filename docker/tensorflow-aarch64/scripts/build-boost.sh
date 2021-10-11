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

export CPLUS_INCLUDE_PATH="/usr/include/python3.8/"

mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
readonly package=boost
readonly boost_src=https://boostorg.jfrog.io/artifactory/main/release/1.70.0/source/boost_1_70_0.tar.bz2
readonly num_cpus=$(grep -c ^processor /proc/cpuinfo)
wget $boost_src
tar --bzip2 -xf boost_1_70_0.tar.bz2
cd boost_1_70_0
./bootstrap.sh --prefix=$PROD_DIR/$package/install
./b2 -j $num_cpus
./b2 headers
sudo ./b2 install
rm -rf $PACKAGE_DIR
