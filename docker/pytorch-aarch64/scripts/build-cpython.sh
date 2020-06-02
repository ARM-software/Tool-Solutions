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

cd $PACKAGE_DIR
readonly package=python
readonly version=$PY_VERSION
readonly src_host=https://github.com/python
readonly src_repo=cpython

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

export CFLAGS="${BASE_CFLAGS} -O3"
export LDFLAGS="${BASE_LDFLAGS} -lpthread"
readonly confflags="" #"--enable-optimizations

install_dir=$PROD_DIR/$package/$version
mkdir Build
cd Build

../configure $confflags # --prefix=$install_dir
make -j $NP_MAKE
make install

update-alternatives --install /usr/bin/python python /usr/local/bin/python3 1
update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip3 1

