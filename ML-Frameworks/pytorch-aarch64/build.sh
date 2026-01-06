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
if [ -f .torch_build_container_id ] || [ -f .torch_ao_build_container_id ] || \
    [ -d ao ] || [ -d ComputeLibrary ] || [ -d pytorch ]; then
    printf "\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n\n" \
        "You appear to have artefacts from a previous build lying around." \
        "Check for any of the following:" \
        "  - .torch_build_container_id" \
        "  - .torch_ao_build_container_id" \
        "  - ao" \
        "  - ComputeLibrary" \
        "  - pytorch"

    if [[ "$*" != *--fresh* ]] && [[ "$*" != *--use-existing-sources* ]]; then
        >&2 printf "\n\n%s\n%s\n%s\n\n\n" \
            "Rerun with one of the following options:" \
            "  - '--fresh': wipe the pre-existing sources and do a fresh build" \
            "  - '--use-existing-sources': reuse the sources as is"
        exit 1
    fi

    # Wipe old build artefacts
    if [[ $* == *--fresh* ]]; then
        # Make sure we can wipe directories created with root privileges in Docker
        if [ -f .torch_build_container_id ]; then
            TORCH_BUILD_CONTAINER=$(cat .torch_build_container_id)
            if [ ! -z "$(docker ps -a --no-trunc | grep $TORCH_BUILD_CONTAINER)" ]; then
                # Change permissions from root
                docker exec $TORCH_BUILD_CONTAINER chown -R $(id -u):$(id -g) /artifacts 2>/dev/null || true
                docker exec $TORCH_BUILD_CONTAINER chown -R $(id -u):$(id -g) /ComputeLibrary 2>/dev/null || true
                docker exec $TORCH_BUILD_CONTAINER chown -R $(id -u):$(id -g) /pytorch 2>/dev/null || true

                # Wipe old container
                docker rm -f $TORCH_BUILD_CONTAINER 2>/dev/null || true
            fi
            rm -f .torch_build_container_id
        fi

        # Make sure we can wipe directories created with root privileges in Docker
        if [ -f .torch_ao_build_container_id ]; then
            TORCH_AO_BUILD_CONTAINER=$(cat .torch_ao_build_container_id)
            if [ ! -z "$(docker ps -a --no-trunc | grep $TORCH_AO_BUILD_CONTAINER)" ]; then
                docker exec $TORCH_AO_BUILD_CONTAINER chown -R $(id -u):$(id -g) /ao

                # Wipe old container
                docker rm -f $TORCH_AO_BUILD_CONTAINER 2>/dev/null || true
            fi
            rm -f .torch_ao_build_container_id
        fi

        # Wipe the other directories; we should have the privileges now
        if [ -d ao ]; then rm -rf ao; fi
        if [ -d ComputeLibrary ]; then rm -rf ComputeLibrary; fi
        if [ -d pytorch ]; then rm -rf pytorch; fi
    fi
fi

if ! [[ $* == *--use-existing-sources* ]]; then
    ./get-source.sh
fi

# We build the wheel with ccache by default; allow disabling it via the --disable-ccache flag
build_wheel_args=()
if [[ "$*" == *--disable-ccache* ]]; then
    build_wheel_args+=(--disable-ccache)
fi
./build-wheel.sh "${build_wheel_args[@]}"

[[ $* == *--wheel-only* ]] && exit 0

# Use the second to last match, otherwise grep finds itself
torch_wheel_name=$(grep -o "torch-.*.whl" $build_log | head -n -1 | tail -n 1)

./build-torch-ao-wheel.sh

# Use the second to last match, otherwise grep finds itself
torch_ao_wheel_name=$(grep -o "torchao-.*.whl" $build_log | head -n -1 | tail -n 1)

# Place the torchao wheel next to the torch wheel
cp "ao/dist/$torch_ao_wheel_name" "results/$torch_ao_wheel_name"

./dockerize.sh "results/$torch_wheel_name" "results/$torch_ao_wheel_name" --build-only
