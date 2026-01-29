#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Note that this script intentionally has no options. It builds *the* PyTorch
# Tool-Solutions, of which there is only one type

# The logic in this script should mirror the upstream build pipelines as closely
# as possible, along with Tool-Solutions specific changes we want to test (e.g.
# installing tbb) or improving local development in a way that doesn't affect
# the result. Currently the upstream logic is defined in
#               pytorch/.github/workflows/_binary-build-linux.yml
# and
#   pytorch/.github/workflows/generated-linux-aarch64-binary-manywheel-nightly.yml

set -eux -o pipefail

PYTHON_VERSION="3.12"
OPENBLAS_VERSION="v0.3.30"
ACL_VERSION="v52.6.0"

PYTHON_TAG="cp$(echo "$PYTHON_VERSION" | tr -d .)-cp$(echo "$PYTHON_VERSION" | tr -d .)"
PYTHON_BIN="/opt/python/${PYTHON_TAG}/bin"

# Specify DOCKER_IMAGE_MIRROR if you want to use a mirror of hub.docker.com
IMAGE_NAME="${DOCKER_IMAGE_MIRROR:-}pytorch/manylinux2_28_aarch64-builder:cpu-aarch64-d8be0384e085f551506bd739678109fa0f5ee7ac"
TORCH_BUILD_CONTAINER_ID_FILE="${PWD}/.torch_build_container_id"

# Output dir for PyTorch wheel and other artifacts
OUTPUT_DIR=${OUTPUT_DIR:-"${PWD}/results"}

# Where folders sit locally
PYTORCH_HOST_DIR="${PWD}/pytorch"
OPENSSL_HOST_DIR="/opt/openssl"
PYTORCH_FINAL_PACKAGE_HOST_DIR="${OUTPUT_DIR}"

# Where folders sit mounted in the container
PYTORCH_ROOT=/pytorch
UTILS=/utils
COMMON_UTILS=/common_utils
PYTORCH_FINAL_PACKAGE_DIR=/artifacts

# Enable ccache support by default.
# NOTE: The default behaviour is to have a project-specific cache directory that we cache
# build artefacts inside and can be easily wiped. These build artefacts are specific to the
# manylinux builder container (and thus compilers) that we use to build the torch wheel. As
# such, you may not want to populate the global ccache cache with them. However, if you wish
# to do so, simply set CCACHE_HOST_DIR to that directory.
CCACHE_HOST_DIR=${CCACHE_HOST_DIR:-"${PWD}/.ccache"}
LOCAL_CCACHE_DIR=/.ccache
CCACHE_MAXSIZE=${CCACHE_MAXSIZE:-}

# If the user wants to use ccache for build caching
ccache_args=()
if [[ "$*" == *--disable-ccache* ]]; then
    ccache_args+=(-e USE_CCACHE=0)
else
    ccache_args+=(-e USE_CCACHE=1)
    mkdir -p "${CCACHE_HOST_DIR}"
    ccache_args+=(
        -e CCACHE_DIR="${LOCAL_CCACHE_DIR}"
        -v "${CCACHE_HOST_DIR}:${LOCAL_CCACHE_DIR}"
    )
fi

# Want a CPU build
DESIRED_CUDA=cpu
GPU_ARCH_TYPE=cpu-aarch64

# Affects the number of jobs used in install_acl.sh and install_openblas.sh
MAX_JOBS=${MAX_JOBS:-$(nproc --ignore=2)}

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
        -e MAX_JOBS=${MAX_JOBS} \
        -e OPENBLAS_VERSION=${OPENBLAS_VERSION} \
        -e ACL_VERSION=${ACL_VERSION} \
        -e BINARY_ENV_FILE=/tmp/env \
        -e BUILD_ENVIRONMENT=linux-aarch64-binary-manywheel \
        -e DESIRED_CUDA=${DESIRED_CUDA} \
        -e DESIRED_PYTHON=${PYTHON_VERSION} \
        -e GITHUB_ACTIONS=0 \
        -e GPU_ARCH_TYPE=${GPU_ARCH_TYPE} \
        -e PACKAGE_TYPE=manywheel \
        -e PYTORCH_FINAL_PACKAGE_DIR="${PYTORCH_FINAL_PACKAGE_DIR}" \
        -e PYTORCH_ROOT="${PYTORCH_ROOT}" \
        -e SKIP_ALL_TESTS=1 \
        -e OPENSSL_ROOT_DIR="${OPENSSL_HOST_DIR}" \
        -e CMAKE_INCLUDE_PATH="${OPENSSL_HOST_DIR}/include" \
        "${ccache_args[@]}" \
        -v "${PYTORCH_HOST_DIR}:${PYTORCH_ROOT}" \
        -v "${PYTORCH_FINAL_PACKAGE_HOST_DIR}:${PYTORCH_FINAL_PACKAGE_DIR}" \
        -v "${PWD}/utils:${UTILS}" \
        -v "${PWD}/../utils:${COMMON_UTILS}" \
        -w / \
        "${IMAGE_NAME}")

    # Provide ccache support
    if [[ "$*" != *--disable-ccache* ]]; then
        docker exec "$TORCH_BUILD_CONTAINER" yum install -y ccache || true
        if [ -n "${CCACHE_MAXSIZE}" ]; then
            docker exec "$TORCH_BUILD_CONTAINER" ccache --max-size="$CCACHE_MAXSIZE" || true
        fi
        docker exec "$TORCH_BUILD_CONTAINER" ccache -z || true
        docker exec "$TORCH_BUILD_CONTAINER" ccache -o compression=true || true
        docker exec "$TORCH_BUILD_CONTAINER" ccache -o compression_level=6 || true
        docker exec "$TORCH_BUILD_CONTAINER" ccache -s || true
    fi

    # Currently changes in these scripts will not be applied without a clean
    # build, which is not ideal for dev work. But we have to balance this with
    # extra time/network traffic when rebuilding many times.
    docker exec $TORCH_BUILD_CONTAINER bash "${PYTORCH_ROOT}/.circleci/scripts/binary_populate_env.sh"

    # Install scons for ACL build
    docker exec $TORCH_BUILD_CONTAINER ${PYTHON_BIN}/python3 -m pip install scons==4.7.0
    docker exec $TORCH_BUILD_CONTAINER ln -sf ${PYTHON_BIN}/scons /usr/local/bin

    # The Docker image comes with a pre-built version of ACL, but we want to build our own
    # so we remove the provided version here
    docker exec "$TORCH_BUILD_CONTAINER" rm -rf /acl

    # Affected by ACL_VERSION set as an environment variable above
    echo "Overriding Arm Compute Library version: ${ACL_VERSION}"
    docker exec "$TORCH_BUILD_CONTAINER" "${PYTORCH_ROOT}/.ci/docker/common/install_acl.sh"

    # Affected by OPENBLAS_VERSION set as an environment variable above
    echo "Installing OpenBLAS version: ${OPENBLAS_VERSION}"
    docker exec "$TORCH_BUILD_CONTAINER" "${PYTORCH_ROOT}/.ci/docker/common/install_openblas.sh"

    echo "Storing torch build container ID in ${TORCH_BUILD_CONTAINER_ID_FILE} for reuse: ${TORCH_BUILD_CONTAINER}"
    echo $TORCH_BUILD_CONTAINER > "${TORCH_BUILD_CONTAINER_ID_FILE}"
else
    docker restart $TORCH_BUILD_CONTAINER
fi

# If there are multiple wheels in the dist directory, an old wheel can be
# erroneously copied to results, so we clear the directory to be sure
docker exec $TORCH_BUILD_CONTAINER rm -rf "${PYTORCH_ROOT}/dist"

# We set OVERRIDE_PACKAGE_VERSION to be based on the date of the latest torch
# commit, this allows us to also install the matching torch* packages, set in
# the Dockerfile. This is what PyTorch does in its nightly pipeline, see
# pytorch/.ci/aarch64_linux/aarch64_wheel_ci_build.py for this logic.
build_date=$(cd $PYTORCH_HOST_DIR && git log --pretty=format:%cs -1 | tr -d '-')
version=$(cat $PYTORCH_HOST_DIR/version.txt| tr -d "[:space:]" )
OVERRIDE_PACKAGE_VERSION="${version%??}.dev${build_date}${TORCH_RELEASE_ID:+"+$TORCH_RELEASE_ID"}"

docker exec $TORCH_BUILD_CONTAINER bash -lc "
  source /tmp/env &&
  BUILD_TEST=0 \
  DO_SETUP_PY_CLEAN_BEFORE_BUILD=0 \
  WIPE_RH_CUDA_AFTER_BUILD=0 \
  OVERRIDE_PACKAGE_VERSION=$OVERRIDE_PACKAGE_VERSION \
  bash ${PYTORCH_ROOT}/.ci/manywheel/build.sh
"

# directories generated by the docker container are owned by root, so transfer ownership to user
docker exec "$TORCH_BUILD_CONTAINER" chown -R "$(id -u)":"$(id -g)" \
    "${PYTORCH_ROOT}" "${PYTORCH_FINAL_PACKAGE_DIR}" "${LOCAL_CCACHE_DIR}"
