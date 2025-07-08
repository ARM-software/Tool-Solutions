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
PYTORCH_HASH=5dfd8a9c7a464bb42e81b8594eefd2fa865e5423  # From viable/strict, July 3rd
IDEEP_HASH=6eb12eaad5e0f7d8c8613c744ac8ba5a0843cb99    # From ideep_pytorch, July 3rd
ONEDNN_HASH=0abfca1947b53c03ee74207e4710941ab6456f3b   # From main, July 3rd
ACL_HASH=f69b48afcc59f1b3b0d4544289249bebba489f0a      # From main, June 26th
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/152361 - Build libgomp (gcc-11) from source
    apply-github-patch pytorch/pytorch 7c54b6b07558c330ee2f95b4793edb3bfbb814c9
    apply-github-patch pytorch/pytorch 3e17ce1619b2d02543a619f6217919b5adb36123
    apply-github-patch pytorch/pytorch 2c884c2b580a93cd0b1e5eea36aa24e3acab91a9

    # https://github.com/pytorch/pytorch/pull/150833 - Pin all root requirements to major versions
    apply-github-patch pytorch/pytorch 51ce4213adb106659abc962fb66b94d595a19e20

    # https://github.com/pytorch/pytorch/pull/151547 - Update OpenBLAS commit
    apply-github-patch pytorch/pytorch b06f8b5dbdc66878bf2492f08f42d7b1ad42a4f3
    apply-github-patch pytorch/pytorch 7e467c44b70a0ba09d52b63e570f1c2fcb05b159
    apply-github-patch pytorch/pytorch 4a596d0c6905c7a7274a479144f9edb4e18c3472
    apply-github-patch pytorch/pytorch 78664d62d73fe9ebf3d08d4382986c7090e447d5
    apply-github-patch pytorch/pytorch 190b3b3069b5ce130c1584d0d4ddd36d6d477801

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD

        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            # https://github.com/uxlfoundation/oneDNN/pull/3022 - cpu: aarch64: enable jit conv for 128
            apply-github-patch uxlfoundation/oneDNN 244422f8cd0aab93d2a184894472c955ebb7bb97
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
