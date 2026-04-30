#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# The logic in this script should mirror the upstream build pipelines as closely
# as possible, along with Tool-Solutions specific changes we want to test (e.g.
# installing tbb) or improving local development in a way that doesn't affect
# the result. Currently the upstream logic is defined in
#               pytorch/.github/workflows/_binary-build-linux.yml
# and
#   pytorch/.github/workflows/generated-linux-aarch64-binary-manywheel-nightly.yml

source ./versions.sh

set -eux -o pipefail

docker_exec() {
    docker exec "$TORCH_BUILD_CONTAINER" "$@"
}

cleanup() {
    local return_code=$?

    if [ -n "${TORCH_BUILD_CONTAINER:-}" ] && docker container inspect "$TORCH_BUILD_CONTAINER" >/dev/null 2>&1; then
        docker_exec chown -R "$(id -u)":"$(id -g)" "${OWNERSHIP_PATHS[@]}" || true
        docker rm -f "$TORCH_BUILD_CONTAINER" >/dev/null 2>&1 || true
    fi

    exit "$return_code"
}

PYTHON_VERSION="3.12"

BUILDER_IMAGE_NAME="${BUILDER_IMAGE_NAME:-local/pytorch-manylinux2_28_aarch64-builder:cpu-aarch64}"

# Output dir for PyTorch wheel and other artifacts. Rename with the "_LOCAL_DIR"
# suffix for consistency with other variables
OUTPUT_LOCAL_DIR="${OUTPUT_DIR:-"${PWD}/results"}"

# Where folders sit locally
PYTORCH_LOCAL_DIR="${PWD}/pytorch"
PYTORCH_FINAL_PACKAGE_LOCAL_DIR="${OUTPUT_LOCAL_DIR}"

# Where folders sit in the container
PYTORCH_CONTAINER_DIR=/pytorch
PYTORCH_FINAL_PACKAGE_CONTAINER_DIR=/artifacts
OPENSSL_CONTAINER_DIR=/opt/openssl

# Enable ccache support by default.
# NOTE: The default behaviour is to have a project-specific cache directory that we cache
# build artefacts inside and can be easily wiped. These build artefacts are specific to the
# manylinux builder container (and thus compilers) that we use to build the torch wheel. As
# such, you may not want to populate the global ccache cache with them. However, if you wish
# to do so, simply set CCACHE_LOCAL_DIR to that directory.
CCACHE_LOCAL_DIR="${CCACHE_LOCAL_DIR:-"${PWD}/.ccache"}"
CCACHE_CONTAINER_DIR=/.ccache
CCACHE_MAXSIZE=${CCACHE_MAXSIZE:-}

# If the user wants to use ccache for build caching.
ccache_args=()
if [[ "$*" == *--disable-ccache* ]]; then
    USE_CCACHE=0
    ccache_args+=(-e USE_CCACHE=0)
else
    USE_CCACHE=1
    ccache_args+=(-e USE_CCACHE=1)
    mkdir -p "${CCACHE_LOCAL_DIR}"
    ccache_args+=(
        -e CCACHE_DIR="${CCACHE_CONTAINER_DIR}"
        -v "${CCACHE_LOCAL_DIR}:${CCACHE_CONTAINER_DIR}"
    )
fi

# Want a CPU build
DESIRED_CUDA=cpu
GPU_ARCH_TYPE=cpu-aarch64

# Affects the number of jobs used in install_acl.sh and install_openblas.sh
MAX_JOBS=${MAX_JOBS:-$(nproc --ignore=2)}

OWNERSHIP_PATHS=(
    "${PYTORCH_CONTAINER_DIR}"
    "${PYTORCH_FINAL_PACKAGE_CONTAINER_DIR}"
)
if [[ "$*" != *--disable-ccache* ]]; then
    OWNERSHIP_PATHS+=("${CCACHE_CONTAINER_DIR}")
fi

mkdir -p "${OUTPUT_LOCAL_DIR}"

trap cleanup EXIT

echo "Building local manywheel builder image with ACL_VERSION=${ACL_VERSION} and OPENBLAS_VERSION=${OPENBLAS_VERSION}"
(
    cd "${PYTORCH_LOCAL_DIR}"
    ACL_VERSION="${ACL_VERSION}" \
    OPENBLAS_VERSION="${OPENBLAS_VERSION}" \
    MAX_JOBS="${MAX_JOBS}" \
    USE_CCACHE="${USE_CCACHE}" \
    ./.ci/docker/manywheel/build.sh \
        manylinux2_28_aarch64-builder:cpu-aarch64 \
        --progress=plain \
        -t "${BUILDER_IMAGE_NAME}"
)

# Based on environment used in pytorch/.github/workflows/_binary-build-linux.yml
# and pytorch/.github/workflows/generated-linux-aarch64-binary-manywheel-nightly.yml
TORCH_BUILD_CONTAINER=$(docker run -t -d \
    -e MAX_JOBS="${MAX_JOBS}" \
    -e BINARY_ENV_FILE=/tmp/env \
    -e BUILD_ENVIRONMENT=linux-aarch64-binary-manywheel \
    -e DESIRED_CUDA="${DESIRED_CUDA}" \
    -e DESIRED_PYTHON="${PYTHON_VERSION}" \
    -e GITHUB_ACTIONS=0 \
    -e GPU_ARCH_TYPE="${GPU_ARCH_TYPE}" \
    -e PACKAGE_TYPE=manywheel \
    -e PYTORCH_FINAL_PACKAGE_DIR="${PYTORCH_FINAL_PACKAGE_CONTAINER_DIR}" \
    -e PYTORCH_ROOT="${PYTORCH_CONTAINER_DIR}" \
    -e SKIP_ALL_TESTS=1 \
    -e OPENSSL_ROOT_DIR="${OPENSSL_CONTAINER_DIR}" \
    -e CMAKE_INCLUDE_PATH="${OPENSSL_CONTAINER_DIR}/include" \
    "${ccache_args[@]}" \
    -v "${PYTORCH_LOCAL_DIR}:${PYTORCH_CONTAINER_DIR}" \
    -v "${PYTORCH_FINAL_PACKAGE_LOCAL_DIR}:${PYTORCH_FINAL_PACKAGE_CONTAINER_DIR}" \
    -w / \
    "${BUILDER_IMAGE_NAME}")

if [[ "$*" != *--disable-ccache* ]]; then
    if [ -n "${CCACHE_MAXSIZE}" ]; then
        docker_exec ccache --max-size="$CCACHE_MAXSIZE" || true
    fi
    docker_exec ccache -z || true
    docker_exec ccache -o compression=true || true
    docker_exec ccache -o compression_level=6 || true
    docker_exec ccache -s || true
fi

docker_exec bash "${PYTORCH_CONTAINER_DIR}/.ci/pytorch/binary_populate_env.sh"

# If there are multiple wheels in the dist directory, an old wheel can be
# erroneously copied to results, so we clear the directory to be sure
docker_exec rm -rf "${PYTORCH_CONTAINER_DIR}/dist"

# We set OVERRIDE_PACKAGE_VERSION to be based on the date of the latest torch
# commit, this allows us to also install the matching torch* packages, set in
# the Dockerfile. This is what PyTorch does in its nightly pipeline, see
# pytorch/.ci/aarch64_linux/aarch64_wheel_ci_build.py for this logic.
build_date=$(cd "$PYTORCH_LOCAL_DIR" && git show -s --format=%cs "${PYTORCH_HASH}" | tr -d '-')
version=$(tr -d "[:space:]" < "${PYTORCH_LOCAL_DIR}/version.txt")
OVERRIDE_PACKAGE_VERSION="${version%??}.dev${build_date}${TORCH_RELEASE_ID:+"+$TORCH_RELEASE_ID"}"

# Build the wheel!
docker_exec bash -lc "
  source /tmp/env &&
  BUILD_TEST=0 \
  DO_SETUP_PY_CLEAN_BEFORE_BUILD=0 \
  WIPE_RH_CUDA_AFTER_BUILD=0 \
  OVERRIDE_PACKAGE_VERSION=$OVERRIDE_PACKAGE_VERSION \
  bash ${PYTORCH_CONTAINER_DIR}/.ci/manywheel/build.sh
"
