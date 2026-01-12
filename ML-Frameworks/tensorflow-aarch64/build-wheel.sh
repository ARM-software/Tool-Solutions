#!/bin/bash

# *******************************************************************************
# Copyright 2024-2026 Arm Limited and affiliates.
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

# Note that this script intentionally has no options. It builds *the* TensorFlow
# Tool-Solutions, of which there is only one type

# The logic in this script should mirror the upstream build pipelines as closely
# as possible, along with Tool-Solutions specific changes we want to test (e.g.
# installing tbb) or improving local development in a way that doesn't affect
# the result (e,.g. unsetting MAX_JOBS). Currently the upstream logic is defined
# in tensorflow/ci/official

set -eux -o pipefail

DEFAULT_PYTHON_VERSION=3.12
PYTHON_VERSION=${PYTHON_VERSION:-$DEFAULT_PYTHON_VERSION}
# TensorFlow's upstream build scripts expect python version to be in format e.g. py311 not 3.11
TF_PY_VERSION="py${PYTHON_VERSION//./}"

TENSORFLOW_DIR="${PWD}/tensorflow"
OUTPUT_DIR=${OUTPUT_DIR:-"${PWD}/results"}

# TFCI determines the docker image and build/test configuration to use (from .bazelrc)
# linux_arm64 defines default build flag from Aarch64 build
# disk_cache to use the local bazel cache
# public_cache can be added together with disk_cache to use TensorFlow's remote Bazel cache which speeds up compile time significantly
# Environment files defined in tensorflow/ci/official/envs
export TFCI=$TF_PY_VERSION,linux_arm64,disk_cache

echo "Building TensorFlow"
(
    cd "${TENSORFLOW_DIR}/ci/official"
    # Overwrite variables from linux_arm64 env
    export TFCI_WHL_BAZEL_TEST_ENABLE=0 # Disable running unit tests on wheel after build
    export TFCI_WHL_SIZE_LIMIT_ENABLE=0 # Disable checking wheel size, currently larger than allowed upstream (245M)
    # This uses TFCI to set build/test environment variables and pull the docker image
    source "./utilities/setup.sh"
    # Build wheel in docker
    tfrun bazel build $TFCI_BAZEL_COMMON_ARGS //tensorflow/tools/pip_package:wheel $TFCI_BUILD_PIP_PACKAGE_ARGS
    tfrun find ./bazel-bin/tensorflow/tools/pip_package -iname "*.whl" -exec cp {} $TFCI_OUTPUT_DIR \;
    tfrun ./ci/official/utilities/rename_and_verify_wheels.sh
)

# Copy wheel to results folder
RESULTS=${RESULTS:-$PWD/results}
mkdir -p $RESULTS
cp tensorflow/build_output/*.whl $RESULTS
