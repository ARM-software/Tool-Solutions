#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2022 Arm Limited and affiliates.
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
readonly package=tensorflow-addons
readonly version=master
readonly src_host=https://github.com/tensorflow
readonly src_repo=addons

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version

python ./configure.py

bazel build build_pip_pkg
bazel-bin/build_pip_pkg artifacts

pip install artifacts/tensorflow_addons-*.whl
