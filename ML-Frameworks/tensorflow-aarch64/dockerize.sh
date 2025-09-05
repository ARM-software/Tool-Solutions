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

set -eux -o pipefail

help_str="dockerize.sh takes a TensorFlow wheel as argument. It \
installs the wheel inside a Docker container with examples and requirements."
if [ "$#" -ne 1 ]; then
    echo $help_str
    exit 1
fi

if ! [ -e "$1" ]; then
    echo "I couldn't find a wheel at $1"
    echo $help_str
    exit 1
fi

docker build -t toolsolutions-tensorflow:latest  \
    --build-arg TENSORFLOW_WHEEL=$1 \
    .
docker run --rm -it toolsolutions-tensorflow:latest
