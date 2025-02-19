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

# # Bail out if sources are already there
if [ -d tensorflow ] ; then
    echo "You appear to have sources already" \

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

# Use the second to last match, otherwise grep finds itself
tf_wheel_name=$(grep -o "tensorflow-.*.whl" $build_log | head -n -1 | tail -n 1)
echo $tf_wheel_name

docker build -t toolsolutions-tensorflow:latest \
    --build-arg TENSORFLOW_WHEEL=results/$tf_wheel_name \
    --build-arg DOCKER_IMAGE_MIRROR \
    .
