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

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=6506da61ed123658ddca003774a5f2eb430c3cad   # Nightly Feb 11, 2025
ONEDNN_HASH=d4b61e983b456f69cced71d8296bd2b2de5fabf4    # main Jan 14, 2025
ACL_HASH=0038c52d6c79b76755c087cda1be4bbf752e272c       # main Jan 6, 2025 (Commit after introduces KleidiAI as third-party module in Bazel build, dependency missing in TensorFlow)

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH
(
    cd tensorflow

    # TensorFlow patches
    apply-github-patch https://github.com/tensorflow/tensorflow 84975 01c30f3277c2b943ebc61a0b23ab402d48b3e1d2 # build(aarch64): Update to oneDNN-3.7 + ACL-24.12

    cd tensorflow

    # Set up workspace to point to local versions of Compute Library and oneDNN
    # Rename existing tf_http_archives
    sed -i -e 's/\"mkl_dnn_acl_compatible\"/\"mkl_dnn_acl_compatible_backup\"/g' workspace2.bzl
    sed -i -e 's/\"compute_library\"/\"compute_library_backup\"/g' workspace2.bzl
    # Insert a new_local_repository for oneDNN and ACL in place of the http_archives
    csplit -f workspace2.bzl. -n 1 workspace2.bzl /'def _tf_repositories():'/+2 '{0}'
    onednn_acl_local_repositories=$'
    native.new_local_repository(
        name = "mkl_dnn_acl_compatible",
        build_file = "//third_party/mkl_dnn:mkldnn_acl.BUILD",
        path = \'./third_party/mkl_dnn/oneDNN\'
    )
    native.local_repository(
        name = "compute_library",
        path = \'./third_party/compute_library/ComputeLibrary\'
    )'
    echo "$onednn_acl_local_repositories" > tensorflow_local-repositories.txt
    cat workspace2.bzl.0 tensorflow_local-repositories.txt workspace2.bzl.1 > workspace2.bzl
    cd ..

    # oneDNN patches
    (
        cd third_party/mkl_dnn
        git-shallow-clone https://github.com/oneapi-src/oneDNN.git $ONEDNN_HASH

        # Apply WIP patches
    )

    # ACL patches
    (
        cd third_party/compute_library
        git-shallow-clone https://review.mlplatform.org/ml/ComputeLibrary $ACL_HASH

        # Apply WIP patches
    )

)