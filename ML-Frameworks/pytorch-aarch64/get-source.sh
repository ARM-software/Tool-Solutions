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
PYTORCH_HASH=e872bf8f888bdbb27a03e03935db61babf7180b8  # 2.8.0.dev20250430 from viable/strict
IDEEP_HASH=2ef932a861439e4cc9bb8baee8424b57573de023    # From ideep_pytorch
ONEDNN_HASH=69150ce5fe1f453af9125ca42a921e017092ccf7   # From main
ACL_HASH=334108c0efc512efdc9576ba957dbcf5b7ee168a      # rc_25_04_29_0
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/143190 - Enable AArch64 CI scripts to be used for local dev
    apply-github-patch pytorch/pytorch 6e5628b1f648d862e8fdd150ad277120b236ed15
    # https://github.com/pytorch/pytorch/pull/140159 - cpu: enable gemm-bf16f32 for SDPA BF16
    apply-github-patch pytorch/pytorch ca4a718be80eb88ca6804b91201e4f98a3e236c8
    apply-github-patch pytorch/pytorch 406fe1fbd066401774c104d125a7ac0b3d6eb52b
    # https://github.com/pytorch/pytorch/pull/152361 - Build libgomp (gcc-11) from source
    apply-github-patch pytorch/pytorch 7c54b6b07558c330ee2f95b4793edb3bfbb814c9
    # https://github.com/pytorch/pytorch/pull/150833 - Pin all root requirements to major versions
    apply-github-patch pytorch/pytorch 02987a7c2e9b249a669723224c8d3cd80c6cb64e

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
