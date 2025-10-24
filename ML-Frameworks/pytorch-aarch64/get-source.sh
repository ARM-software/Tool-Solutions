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
PYTORCH_HASH=45d9dcccc5bfb46a9eaca037270278bc3d7c95ea  # 2.10.0.dev20250923 from viable/strict, September 23rd
IDEEP_HASH=fd11055f4800ac89291e30b5387a79a1e6496aa6    # From ideep_pytorch, September 10th
ONEDNN_HASH=9e8f619477469ed75d323d4915bf7a2513f01713   # From main, September 23rd
ACL_HASH=531a4968cecb7b4fc0a3b65482e2c524289e087e      # From main, September 23rd
TORCH_AO_HASH=8e2ca35ea603349e71c2467e10fd371e34bf52bc # From main, September 23rd
KLEIDIAI_HASH=bd2e6ae060014035e25bf4986be682762c446c2d # v1.14 from main

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
    apply-github-patch pytorch/pytorch 4d344570e5a114fa522e3370c5d59161e2ed8619

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

    # https://github.com/pytorch/pytorch/pull/161049 - optimised SVE exp_u20 implementation
    # based on Arm Optimised Routines - https://github.com/ARM-software/optimized-routines
    apply-github-patch pytorch/pytorch 3de5651bafcdabbc52d5205c0de3976188eba7fb

    # https://github.com/pytorch/pytorch/pull/160080 - VLA Vectorized POC
    apply-github-patch pytorch/pytorch e84eabd4f9761362ba081512b2922b4f18c97d41
    apply-github-patch pytorch/pytorch a49982892480af69fae8bb19505b31b3304cda7a
    apply-github-patch pytorch/pytorch 6ca9dc026d8d65c575c880ebe8b678f724d609a1
    apply-github-patch pytorch/pytorch 3b92a1adfe40ca9c37e7db523eccaad4358d949c
    apply-github-patch pytorch/pytorch 0384f48daa4b27d155632329521128212dd6fda3
    apply-github-patch pytorch/pytorch bf4b0e8c41c75d9106e2e432c6b9a00319295930
    apply-github-patch pytorch/pytorch dae9a71d99faa19764c47c602cb92bbf72ca7260
    apply-github-patch pytorch/pytorch 8ac81dba2155808427ec3943c4d057f6b05b23d6

    # https://github.com/pytorch/pytorch/pull/159859 - PoC LUT optimisation for GELU bf16 operators
    apply-github-patch pytorch/pytorch ebcc874e317f9563ab770fc5c27df969e0438a5e

    # https://github.com/pytorch/pytorch/pull/164741 - Enable mimalloc on non-Windows platforms and
    # make default for AArch64 builds
    apply-github-patch pytorch/pytorch 9f6a4018f6e7d77d4ac974a38f68fbd7c8eef25c

    # https://github.com/pytorch/pytorch/pull/144992 - Enable fp16 linear layers in PyTorch via ACL
    apply-github-patch pytorch/pytorch 00076d21ed6cd7df2a61165b1fb1d0a436f4e403
    apply-github-patch pytorch/pytorch 850db41fe6d33c6460740da781b40e009f04a47c

    # Remove deps that we don't need for manylinux AArch64 CPU builds before fetching.
    # Only used when jni.h is present (see .ci/pytorch/build.sh:116), which is not the case for manylinux
    git rm android/libs/fbjni
    # Only needed if USE_ROCM=ON, which is OFF for AArch64
    git rm third_party/composable_kernel
    # Not used for CPU only builds
    git rm third_party/cudnn_frontend
    git rm third_party/cutlass
    git rm third_party/flash-attention
    git rm third_party/NVTX

    # Update submodules
    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)

    # Remove deps that we don't need which come from third party. It would be nice to avoid
    # fetching completely, but this was tricky with git submodule update --init --checkout --force --recursive
    (
        cd third_party/fbgemm
        git rm external/cutlass
        git rm external/composable_kernel
        git rm -r fbgemm_gpu/experimental
    )
    (
        cd third_party/aiter
        git rm 3rdparty/composable_kernel
    )

    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD

        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            # https://github.com/uxlfoundation/oneDNN/pull/3022 - cpu: aarch64: enable jit conv for 128
            apply-github-patch uxlfoundation/oneDNN b43cc9c4526c16a292860dadf34b3585b1f33531
        )
    )
    (
        cd third_party/kleidiai
        git fetch origin $KLEIDIAI_HASH && git clean -f && git checkout -f FETCH_HEAD
    )

    # rebuild third_party/LICENSES_BUNDLED.txt after modifying PyTorch submodules if we can
    # this will also get done in PyTorch build too
    if command -v python3 >/dev/null 2>&1; then
        python3 third_party/build_bundled.py
    fi
)

git-shallow-clone https://github.com/ARM-software/ComputeLibrary.git $ACL_HASH

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
