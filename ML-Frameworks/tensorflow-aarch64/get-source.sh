#!/bin/bash

# *******************************************************************************
# Copyright 2024-2025 Arm Limited and affiliates.
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

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=ab8aab720f1648f6a470b159b0d1aea3a5b0df81 # 2.20.0-dev0 from master, 25th July 2025

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH

(
    cd tensorflow

    # Apply TensorFlow WIP patches here

    # https://github.com/tensorflow/tensorflow/pull/93951 - build(aarch64): Update to oneDNN-3.7 + ACL-24.12 (fix)
    apply-github-patch tensorflow/tensorflow e9cd9ea7d5f52b6c6740ce4e486e0fce554a26a4
)
