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
readonly package=tensorflow-io-gcs-filesystem
readonly version=0.21.0
readonly src_host=https://github.com/tensorflow
readonly src_repo=io

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

python setup.py --project tensorflow-io-gcs-filesystem install
