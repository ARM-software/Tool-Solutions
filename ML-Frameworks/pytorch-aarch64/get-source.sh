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
PYTORCH_HASH=4e2ddb5db67617f9f5309c8bba0c17adc84cadbc  # 2.9.0.dev20250808 from viable/strict, August 8th
IDEEP_HASH=3527b0bf2127aa2de93810feb6906d173c24037f    # From ideep_pytorch, August 1st
ONEDNN_HASH=7e85b94b5f6be27b83c5435603ab67888b99da32   # From main, August 1st
ACL_HASH=3c32d706d0245dcb55181c8ced526eab05e2ff8d      # From main, August 1st
TORCH_AO_HASH=8d4a5d83d7be4d7807feabe38d37704c92d40900 # From main, August 1st
KLEIDIAI_HASH=8ca226712975f24f13f71d04cda039a0ee9f9e2f # v1.12 from main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    # Apply patches to PyTorch build
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/152361 - Build libgomp (gcc-11) from source
    apply-github-patch pytorch/pytorch 7c54b6b07558c330ee2f95b4793edb3bfbb814c9
    apply-github-patch pytorch/pytorch 3e17ce1619b2d02543a619f6217919b5adb36123
    apply-github-patch pytorch/pytorch 2c884c2b580a93cd0b1e5eea36aa24e3acab91a9
    apply-github-patch pytorch/pytorch c4c280eb27859221159108356b7c91376202cdd8

    # https://github.com/pytorch/pytorch/pull/160184 - Draft: separate reqs for manywheel build and pin
    # Note: as part of this patch, setuptools is pinned to ~= 78.1.1 which is not affected by
    # CVE-2025-47273 and CVE-2024-6345
    apply-github-patch pytorch/pytorch 6d61f487b6ca98b3d80f9e7ecc0a49a1ab528535


    # https://github.com/pytorch/pytorch/pull/158250 - Ingtegrate INT4→BF16 via KleidiAI, with fallback
    apply-github-patch pytorch/pytorch 7c55f2af0adf9ce62c2226e739a3c84902fe0048
    apply-github-patch pytorch/pytorch 8c27947566c85d44bc7dcd7189db5da608453bbb
    apply-github-patch pytorch/pytorch 15d78c833b032d3c76b70b12a5f2762fa87d2640
    apply-github-patch pytorch/pytorch 186cbcf641f99a301cb26013e8d74d444ad1dcb9
    apply-github-patch pytorch/pytorch a6128ce3a0d2080d80e6fa59061d6c085865376c
    apply-github-patch pytorch/pytorch 52ee4ddc9a5a9cec8793b1ffeb0d74113e3da417
    apply-github-patch pytorch/pytorch ab2a6760e4a4891accbacb9187cf3782cb4b55c3
    apply-github-patch pytorch/pytorch 93384233d166dccab5724f9d2e50b6eb3f47cbe6
    apply-github-patch pytorch/pytorch 9f6d435629dd251620a1e17b8baa6bc18997f8ab
    apply-github-patch pytorch/pytorch b68b7867a72fe2ef4c38f9a3cdd93693700a182e

    # https://github.com/pytorch/pytorch/pull/160080 - VLA Vectorized POC
    # Includes optimised SVE exp() implementation
    apply-github-patch pytorch/pytorch 3de5651bafcdabbc52d5205c0de3976188eba7fb
    apply-github-patch pytorch/pytorch d5c1aedd5cb85b760abe76099efe64aa535bf1ea
    apply-github-patch pytorch/pytorch b1496344c65638f25547b841bb2c470127b7e420
    apply-github-patch pytorch/pytorch fd5f544e87e8c3d6890815ae28f1dc807331643a
    apply-github-patch pytorch/pytorch 01d97374f5492ca2e1f1eb487e74667a78a00b71
    apply-github-patch pytorch/pytorch ea3fca1a47f3673eaf778505142cde765b3ab725
    apply-github-patch pytorch/pytorch f5f5e4f802824344ce90c1f37df124990dea934c
    apply-github-patch pytorch/pytorch a57478fa655ceff0a910fc936df89b7647ce0e39

    # https://github.com/pytorch/pytorch/pull/159859 - PoC LUT optimisation for GELU bf16 operators
    apply-github-patch pytorch/pytorch ebcc874e317f9563ab770fc5c27df969e0438a5e

    # Update submodules
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
            apply-github-patch uxlfoundation/oneDNN 466ee88db85db46c8e9cc0535e526efca6308329
        )
    )
    (
        cd third_party/kleidiai
        git fetch origin $KLEIDIAI_HASH && git clean -f && git checkout -f FETCH_HEAD
    )

)

git-shallow-clone https://review.mlplatform.org/ml/ComputeLibrary $ACL_HASH
(
    cd ComputeLibrary
    # Improve gemm_interleaved 2D vs 1D blocking heuristic
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1
)

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
