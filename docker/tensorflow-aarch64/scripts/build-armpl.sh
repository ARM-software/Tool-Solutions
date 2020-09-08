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
readonly package=armpl
readonly version=$ARMPL_VERSION
readonly tar_host="https://developer.arm.com/-/media/Files/downloads/hpc/arm-performance-libraries/$(echo $version | sed "s/\./-/g")/Ubuntu16.04"
readonly tar_name="arm-performance-libraries_${version}_Ubuntu-16.04_gcc-9.3"

mkdir -p $package
cd $package

# Download, untar and install ArmPL
wget ${tar_host}/${tar_name}".tar"
tar -xvf ${tar_name}.tar
rm ${tar_name}.tar
cd ${tar_name}

./arm-performance-libraries_${version}_Ubuntu-16.04.sh --accept --install-to $PROD_DIR/$package
