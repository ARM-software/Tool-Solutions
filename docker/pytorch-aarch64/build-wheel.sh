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

# Note that this script intentionally has no options. It builds *the* PyTorch
# Tool-Solutions, of which there is only one type

set -eux -o pipefail

PYTHON_VERSION="3.10"

# Transition to pytorch/manylinux2_28_aarch64-builder once
# https://github.com/pytorch/pytorch/pull/137696 goes in
IMAGE_NAME="pytorch/manylinuxaarch64-builder:cpu-aarch64-3a2ab9584f6ce69bf9730c822fd08375c592bf38"
TORCH_BUILD_CONTAINER_ID_FILE="${PWD}/.torch_build_container_id"

# Output dir for PyTorch wheel and other artifacts
OUTPUT_DIR=${OUTPUT_DIR:-"${PWD}/results"}
PYTORCH_FINAL_PACKAGE_DIR=$OUTPUT_DIR

TEST_VENV=aarch64_env_test

BUILDER_HOST_DIR="${PWD}/builder"
PYTORCH_HOST_DIR="${PWD}/pytorch"
ACL_HOST_DIR="${PWD}/ComputeLibrary"

PYTORCH_ROOT=/pytorch
BUILDER_ROOT=/builder

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
        -e BUILDER_ROOT=$BUILDER_ROOT \
        -e BUILD_ENVIRONMENT=linux-aarch64-binary-manywheel \
        -e DESIRED_CUDA=cpu \
        -e DESIRED_PYTHON=$PYTHON_VERSION \
        -e GITHUB_ACTIONS=0 \
        -e GPU_ARCH_TYPE=cpu-aarch64 \
        -e PACKAGE_TYPE=manywheel \
        -e PYTORCH_FINAL_PACKAGE_DIR=$PYTORCH_FINAL_PACKAGE_DIR \
        -e PYTORCH_ROOT=$PYTORCH_ROOT \
        -e SKIP_ALL_TESTS=1 \
        -e PYTORCH_EXTRA_INSTALL_REQUIREMENTS="nvidia-cuda-nvrtc-cu12==12.1.105; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cuda-runtime-cu12==12.1.105; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cuda-cupti-cu12==12.1.105; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cudnn-cu12==8.9.2.26; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cublas-cu12==12.1.3.1; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cufft-cu12==11.0.2.54; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-curand-cu12==10.3.2.106; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cusolver-cu12==11.4.5.107; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-cusparse-cu12==12.1.0.106; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-nccl-cu12==2.19.3; platform_system == 'Linux' and platform_machine == 'x86_64' | nvidia-nvtx-cu12==12.1.105; platform_system == 'Linux' and platform_machine == 'x86_64'" \
        -e OPENSSL_ROOT_DIR=/opt/openssl \
        -e CMAKE_INCLUDE_PATH="/opt/openssl/include" \
        -e TEST_VENV=$TEST_VENV \
        -v "${PYTORCH_HOST_DIR}:${PYTORCH_ROOT}" \
        -v "${BUILDER_HOST_DIR}:${BUILDER_ROOT}" \
        -v "${PYTORCH_FINAL_PACKAGE_DIR}:/artifacts" \
        -v "${ACL_HOST_DIR}:/ComputeLibrary" \
        -w / \
        "${IMAGE_NAME}")

    docker exec -t $TORCH_BUILD_CONTAINER bash -c "$BUILDER_ROOT/aarch64_linux/aarch64_ci_setup.sh"
    docker exec -t $TORCH_BUILD_CONTAINER bash -c "python${PYTHON_VERSION} -m venv $TEST_VENV"
    docker exec -t $TORCH_BUILD_CONTAINER bash -c "source $TEST_VENV/bin/activate && pip install -r $PYTORCH_ROOT/.ci/docker/requirements-ci.txt && pip install ninja==1.10.0.post1"

    docker exec -t $TORCH_BUILD_CONTAINER bash /pytorch/.ci/docker/common/install_openblas.sh

    echo "Storing torch build container id in $TORCH_BUILD_CONTAINER_ID_FILE for reuse: $TORCH_BUILD_CONTAINER"
    echo $TORCH_BUILD_CONTAINER > "$TORCH_BUILD_CONTAINER_ID_FILE"
else
    docker restart $TORCH_BUILD_CONTAINER
fi

docker exec -t $TORCH_BUILD_CONTAINER bash -c "rm -rf /pytorch/dist"

docker exec -t $TORCH_BUILD_CONTAINER bash -c "bash /pytorch/.circleci/scripts/binary_populate_env.sh"
# We unset OVERRIDE_PACKAGE_VERSION which is written to /tmp/env by
# populate_binary_env.sh. unsetting makes aarch64_wheel_ci_build.py set it from
# the last PyTorch commit date. This allows us to fix a torchvision package in
# Dockerfile
docker exec -t $TORCH_BUILD_CONTAINER bash -c "source /tmp/env && unset OVERRIDE_PACKAGE_VERSION && bash /builder/aarch64_linux/aarch64_ci_build.sh"
# directories generated by the docker container are owned by root, so transfer ownership to user
docker exec $TORCH_BUILD_CONTAINER chown -R $(id -u):$(id -g) $PYTORCH_ROOT
