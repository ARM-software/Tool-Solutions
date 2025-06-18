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
PYTORCH_HASH=3040ca6d0f8558e39919b14eebeacc34ddf980f5   # main June 10th
IDEEP_HASH=2ef932a861439e4cc9bb8baee8424b57573de023     # main June 10th
ONEDNN_HASH=106a7b41bc4156297b8a88cd1951304b739cc427    # main June 10th
ACL_HASH=6bc1c7b8d0756272e2a97a7489e13de90f864326       # main June 9th
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/152361 - Build libgomp (gcc-11) from source
    apply-github-patch pytorch/pytorch 7c54b6b07558c330ee2f95b4793edb3bfbb814c9

    # https://github.com/pytorch/pytorch/pull/150833 - Pin all root requirements to major versions
    apply-github-patch pytorch/pytorch 494dd1c84c508c20f2e688c46513f22bbcff175d

    # https://github.com/pytorch/pytorch/pull/151547 - Update OpenBLAS commit
    apply-github-patch pytorch/pytorch 8e3ad3a917e0f0e60a89f647897f4d4c1f5f835a
    apply-github-patch pytorch/pytorch 0218b65bcf61971c1861cfe8bc586168b73aeb5f
    apply-github-patch pytorch/pytorch 53fdcf26b63fbb223b6f01d00608c951541c4ce3
    apply-github-patch pytorch/pytorch d1355a4d4ed7d7f1f052c4f613974885b2e8a05c

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD

        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            # https://github.com/uxlfoundation/oneDNN/pull/3922 - cpu: aarch64: enable jit conv for 128
            apply-github-patch uxlfoundation/oneDNN 4a00e92b995388192e666ee332554e4ef65b484a
        )
    )
)

git-shallow-clone https://review.mlplatform.org/ml/ComputeLibrary $ACL_HASH
(
    cd ComputeLibrary
    # Improve gemm_interleaved 2D vs 1D blocking heuristic
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1
)

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
(
    cd ao
    # https://github.com/pytorch/ao/pull/1447 - Add support for kleidiai quantization schemes
    apply-github-patch pytorch/ao 738d7f2c5a48367822f2bf9d538160d19f02341e
)
