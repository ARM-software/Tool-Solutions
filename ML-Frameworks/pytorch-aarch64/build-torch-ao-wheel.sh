# #!/bin/bash

# *******************************************************************************
# Copyright 2024 Arm Limited and affiliates.
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

# Note that this script intentionally has no options. It builds *the* torchao
# Tool-Solutions, of which there is only one type

set -eux -o pipefail

PYTHON_VERSION="3.10"

# Transition to pytorch/manylinux2_28_aarch64-builder once
# https://github.com/pytorch/pytorch/pull/137696 goes in
IMAGE_NAME="pytorch/manylinuxaarch64-builder:cpu-aarch64-main"
TORCH_BUILD_CONTAINER_ID_FILE="${PWD}/.torch_ao_build_container_id"

TEST_VENV=aarch64_env_test_torch_ao

TORCH_AO_HOST_DIR="${PWD}/ao"

TORCH_AO_ROOT=/ao

if [ -f "$TORCH_BUILD_CONTAINER_ID_FILE" ]; then
    TORCH_BUILD_CONTAINER=$(cat $TORCH_BUILD_CONTAINER_ID_FILE)
    echo "Found an existing torch build container id: $TORCH_BUILD_CONTAINER"
else
    TORCH_BUILD_CONTAINER=""
    echo "Did not find torch build container id in $(readlink -f $TORCH_BUILD_CONTAINER_ID_FILE), we will create one later"
fi

if ! docker container inspect $TORCH_BUILD_CONTAINER >/dev/null 2>&1 ; then

    TORCH_BUILD_CONTAINER=$(docker run -t -d \
        -e BINARY_ENV_FILE=/tmp/env \
        -e BUILD_ENVIRONMENT=linux-aarch64-binary-manywheel \
        -e DESIRED_CUDA=cpu \
        -e DESIRED_PYTHON=$PYTHON_VERSION \
        -e GITHUB_ACTIONS=0 \
        -e GPU_ARCH_TYPE=cpu-aarch64 \
        -e PACKAGE_TYPE=manywheel \
        -e TORCH_AO_ROOT=$TORCH_AO_ROOT \
        -e SKIP_ALL_TESTS=1 \
        -e TEST_VENV=$TEST_VENV \
        -v "${TORCH_AO_HOST_DIR}:${TORCH_AO_ROOT}" \
        -w / \
        "${IMAGE_NAME}")

    docker exec -t $TORCH_BUILD_CONTAINER bash -c "python${PYTHON_VERSION} -m venv $TEST_VENV"
    docker exec -t $TORCH_BUILD_CONTAINER bash -c "source $TEST_VENV/bin/activate && pip install typing_extensions torch wheel numpy --no-deps"

    echo "Storing torch build container id in $TORCH_BUILD_CONTAINER_ID_FILE for reuse: $TORCH_BUILD_CONTAINER"
    echo $TORCH_BUILD_CONTAINER > "$TORCH_BUILD_CONTAINER_ID_FILE"
else
    docker restart $TORCH_BUILD_CONTAINER
fi

docker exec -t $TORCH_BUILD_CONTAINER bash -c "rm -rf ${TORCH_AO_ROOT}/build ${TORCH_AO_ROOT}/dist"
docker exec -t $TORCH_BUILD_CONTAINER bash -c "source $TEST_VENV/bin/activate && cd $TORCH_AO_ROOT && python${PYTHON_VERSION} setup.py bdist_wheel"
# directories generated by the docker container are owned by root, so transfer ownership to user
docker exec $TORCH_BUILD_CONTAINER chown -R $(id -u):$(id -g) $TORCH_AO_ROOT
