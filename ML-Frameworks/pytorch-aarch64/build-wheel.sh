# #!/bin/bash

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

# Note that this script intentionally has no options. It builds *the* PyTorch
# Tool-Solutions, of which there is only one type

# The logic in this script should mirror the upstream build pipelines as closely
# as possible, along with Tool-Solutions specific changes we want to test (e.g.
# installing tbb) or improving local development in a way that doesn't affect
# the result (e,.g. unsetting MAX_JOBS). Currently the upstream logic is defined
# in pytorch/.github/workflows/_binary-build-linux.yml and
# pytorch/.github/workflows/generated-linux-aarch64-binary-manywheel-nightly.yml

set -eux -o pipefail

PYTHON_VERSION="3.10"

# Specify DOCKER_IMAGE_MIRROR if you want to use a mirror of hub.docker.com
IMAGE_NAME="${DOCKER_IMAGE_MIRROR:-}pytorch/manylinux2_28_aarch64-builder:cpu-aarch64-a040006da76a51c4f660331e9abd3affe5a4bd81"
TORCH_BUILD_CONTAINER_ID_FILE="${PWD}/.torch_build_container_id"

# Output dir for PyTorch wheel and other artifacts
OUTPUT_DIR=${OUTPUT_DIR:-"${PWD}/results"}
PYTORCH_FINAL_PACKAGE_DIR=$OUTPUT_DIR

PYTORCH_HOST_DIR="${PWD}/pytorch"
ACL_HOST_DIR="${PWD}/ComputeLibrary"

PYTORCH_ROOT=/pytorch

if [ -f "$TORCH_BUILD_CONTAINER_ID_FILE" ]; then
    TORCH_BUILD_CONTAINER=$(cat $TORCH_BUILD_CONTAINER_ID_FILE)
    echo "Found an existing torch build container id: $TORCH_BUILD_CONTAINER"
else
    TORCH_BUILD_CONTAINER=""
    echo "Did not find torch build container id in $(readlink -f $TORCH_BUILD_CONTAINER_ID_FILE), we will create one later"
fi

if ! docker container inspect $TORCH_BUILD_CONTAINER >/dev/null 2>&1 ; then

    # Based on environment used in pytorch/.github/workflows/_binary-build-linux.yml
    # and pytorch/.github/workflows/generated-linux-aarch64-binary-manywheel-nightly.yml
    TORCH_BUILD_CONTAINER=$(docker run -t -d \
        -e BINARY_ENV_FILE=/tmp/env \
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
        -v "${PYTORCH_HOST_DIR}:${PYTORCH_ROOT}" \
        -v "${PYTORCH_FINAL_PACKAGE_DIR}:/artifacts" \
        -v "${ACL_HOST_DIR}:/ComputeLibrary" \
        -w / \
        "${IMAGE_NAME}")

    # Currently changes in these scripts will not be applied without a clean
    # build, which is not ideal for dev work. But we have to balance this with
    # extra time/network traffic when rebuilding many times.
    docker exec -t $TORCH_BUILD_CONTAINER bash -c $PYTORCH_ROOT/.circleci/scripts/binary_populate_env.sh
    docker exec -t $TORCH_BUILD_CONTAINER bash -c "$PYTORCH_ROOT/.ci/aarch64_linux/aarch64_ci_setup.sh"

    docker exec -t $TORCH_BUILD_CONTAINER bash -c "yum install -y tbb tbb-devel"

    # This must be in this if block because it cannot handle being called twice
    docker exec -t $TORCH_BUILD_CONTAINER bash -c "bash $PYTORCH_ROOT/.ci/docker/common/install_openblas.sh"

    echo "Storing torch build container id in $TORCH_BUILD_CONTAINER_ID_FILE for reuse: $TORCH_BUILD_CONTAINER"
    echo $TORCH_BUILD_CONTAINER > "$TORCH_BUILD_CONTAINER_ID_FILE"
else
    docker restart $TORCH_BUILD_CONTAINER
fi

# If there are multiple wheels in the dist directory, an old wheel can be
# erroneously copied to results, so we clear the directory to be sure
docker exec -t $TORCH_BUILD_CONTAINER bash -c "rm -rf $PYTORCH_ROOT/dist"

# We unset OVERRIDE_PACKAGE_VERSION which is written to /tmp/env by
# populate_binary_env.sh. unsetting makes aarch64_wheel_ci_build.py set it from
# the last PyTorch commit date. This allows us to fix a torchvision package in
# Dockerfile
# We unset MAX_JOBS from 12 (written to /tmp/env by populate_binary_env.sh) to
# let any downstream functions to decide. Currently nproc when ninja is used,
# but ideally we would let ninja make the right choice, but nproc is good enough
docker exec -t $TORCH_BUILD_CONTAINER \
    bash -c "source /tmp/env && unset OVERRIDE_PACKAGE_VERSION MAX_JOBS && bash $PYTORCH_ROOT/.ci/aarch64_linux/aarch64_ci_build.sh"

# directories generated by the docker container are owned by root, so transfer ownership to user
docker exec $TORCH_BUILD_CONTAINER chown -R $(id -u):$(id -g) $PYTORCH_ROOT
