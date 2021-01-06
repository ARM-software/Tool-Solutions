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

cd /home/$DOCKER_USER
readonly package=benchmarks
readonly src_host=https://github.com/tensorflow
readonly src_repo=benchmarks

if [[ $tf_id == '1' ]]; then
  src_branch=cnn_tf_v1.15_compatible
elif [[ $tf_id == '2' ]]; then
  src_branch=cnn_tf_v2.1_compatible
else
  echo 'Invalid TensorFlow version when installing benchmarks'
  exit 1
fi

# Clone tensorflow and benchmarks
git clone -b ${src_branch} ${src_host}/${src_repo}.git
