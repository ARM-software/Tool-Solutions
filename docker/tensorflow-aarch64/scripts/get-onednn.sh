#!/usr/bin/env bash

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

readonly package=onednn
readonly version=$ONEDNN_VERSION
readonly tf_id=$TF_VERSION_ID
readonly src_host=https://github.com/oneapi-src
readonly src_repo=oneDNN

mkdir -p $PROD_DIR/$package/release
cd $PROD_DIR/$package/release
echo "oneDNN VERSION" $version
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version
