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

# exec redirects all output from now on into a file and stdout
build_log=build-$(git rev-parse --short=7 HEAD)-$(date '+%Y-%m-%dT%H-%M-%S').log
exec &> >(tee -a $build_log)

# Bail out if sources are already there
if [ -d pytorch ] || [ -d builder ] || [ -d ComputeLibrary ] ; then
    echo "You appear to have sources already (pytorch/builder/ComputeLibrary)" \

    if ! ([[ $* == *--force* ]] || [[ $* == *--use-existing-sources* ]]) ; then
        >2& echo "rerun with --force to overwrite sources or with" \
                 "--use-existing-sources to build your existing sources."
        exit 1
    fi
fi

if ! [[ $* == *--use-existing-sources* ]]; then
    ./get-source.sh
fi

./build-wheel.sh

[[ $* == *--wheel-only* ]] && exit 0

# Use the second to last match, otherwise grep finds itself
torch_wheel_name=$(grep -o "torch-.*.whl" $build_log | head -n -1 | tail -n 1)

./build-torch-ao-wheel.sh

# Use the second to last match, otherwise grep finds itself
torch_ao_wheel_name=$(grep -o "torchao-.*.whl" $build_log | head -n -1 | tail -n 1)

DOCKER_BUILDKIT=1 docker build -t toolsolutions-pytorch:latest \
    --build-arg TORCH_WHEEL=results/$torch_wheel_name \
    --build-arg DOCKER_IMAGE_MIRROR \
    --build-arg TORCH_AO_WHEEL=ao/dist/$torch_ao_wheel_name \
    --build-arg USERNAME=ubuntu \
    .
