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

PYTORCH_HASH=93fef4bd1dd265588863929e35d9ac89328d5695  # 2.10.0.dev20251124 from viable/strict, Nov 24th
IDEEP_HASH=3724bec97a77ce990e8c6dc5e595bb3beee75257    # From ideep_pytorch, Nov 24th
ONEDNN_HASH=0b8a866c009b03f322e6526d7c33cfec84a4a97a   # From main, Nov 25th
TORCH_AO_HASH=ab6bc89512d912c17a79ed8d4d709612d3e32884 # From main, Nov 25th
KLEIDIAI_HASH=94d6cc40689f44d308dbd57cb842e335fdd958f1 # v1.17.0 from main, Nov 17th

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    # Apply patches to PyTorch build
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/167829 - Refactor ACL and OpenBLAS install scripts on AArch64
    # Note: as part of this patch, setuptools is pinned to ~= 78.1.1 which is not affected by
    # CVE-2025-47273 and CVE-2024-6345
    apply-github-patch pytorch/pytorch 69db12b465887df96d27fe2bb93746ac334577f1
    apply-github-patch pytorch/pytorch 5184c373a8bc77809b6e59361e191d4e78d6a824

    # FIXME: Temporarily disabled; to be updated in a later PR
    # # https://github.com/pytorch/pytorch/pull/160184 - Draft: separate reqs for manywheel build and pin
    # # Note: as part of this patch, setuptools is pinned to ~= 78.1.1 which is not affected by
    # # CVE-2025-47273 and CVE-2024-6345
    # apply-github-patch pytorch/pytorch 4d344570e5a114fa522e3370c5d59161e2ed8619

    # https://github.com/pytorch/pytorch/pull/167720 - Allow missing cutlass file if CUDA disabled
    apply-github-patch pytorch/pytorch 6fbbfe712d89895824e466a4e3ae6a0f35626078

    # https://github.com/pytorch/pytorch/pull/159859 - PoC LUT optimisation for GELU bf16 operators
    apply-github-patch pytorch/pytorch ebcc874e317f9563ab770fc5c27df969e0438a5e

    # https://github.com/pytorch/pytorch/pull/144992 - Enable fp16 linear layers in PyTorch via ACL
    apply-github-patch pytorch/pytorch 00076d21ed6cd7df2a61165b1fb1d0a436f4e403
    apply-github-patch pytorch/pytorch 850db41fe6d33c6460740da781b40e009f04a47c

    # https://github.com/pytorch/pytorch/pull/167328 - Build cpuinfo into c10 shared library
    apply-github-patch pytorch/pytorch 715ba4203ccaa71f7cb8f351fa135110b6f7ecd4
    apply-github-patch pytorch/pytorch e90d7480934224777722d4093795f96c667e5520
    apply-github-patch pytorch/pytorch f5bfabc03efb34416378036ab717512d5611d8f4

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

            # https://github.com/uxlfoundation/oneDNN/pull/4237 - cpu: aarch64: jit_reorder: cache blocking 4/8 inner blocks
            apply-github-patch uxlfoundation/oneDNN 8bdff1a2a6625432701363185a9bd34f7c22f241
            # https://github.com/uxlfoundation/oneDNN/pull/4377 - cpu: aarch64: conv: optimize brgemm
            apply-github-patch uxlfoundation/oneDNN 93b8cc29afc6ee9c2856436a5f5b10d5f1f2f2f1
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

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
(
    # Remove cutlass directory
    cd ao
    git rm third_party/cutlass
)