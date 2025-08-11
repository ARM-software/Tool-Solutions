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
PYTORCH_HASH=6662a76f5975bae56ce9171b0afad32b53f89c25  # 2.9.0.dev20250731 from viable/strict, August 1st
IDEEP_HASH=3527b0bf2127aa2de93810feb6906d173c24037f    # From ideep_pytorch, August 1st
ONEDNN_HASH=7e85b94b5f6be27b83c5435603ab67888b99da32   # From main, August 1st
ACL_HASH=3c32d706d0245dcb55181c8ced526eab05e2ff8d      # From main, August 1st
TORCH_AO_HASH=ebfe1736c4442970835b6eda833c0bc5a1ce2dda # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/152361 - Build libgomp (gcc-11) from source
    apply-github-patch pytorch/pytorch 7c54b6b07558c330ee2f95b4793edb3bfbb814c9
    apply-github-patch pytorch/pytorch 3e17ce1619b2d02543a619f6217919b5adb36123
    apply-github-patch pytorch/pytorch 2c884c2b580a93cd0b1e5eea36aa24e3acab91a9
    apply-github-patch pytorch/pytorch c4c280eb27859221159108356b7c91376202cdd8

    # https://github.com/pytorch/pytorch/pull/160184 - Draft: separate reqs for manywheel build and pin
    apply-github-patch pytorch/pytorch 9a8b0df99eac62e7ec6199dd0223a80d26e2dee0

    # https://github.com/pytorch/pytorch/pull/159859 - PoC LUT optimisation for GELU bf16 operators
    apply-github-patch pytorch/pytorch 51626269d3730df1a6b465fa0191074fc31f7c29

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
