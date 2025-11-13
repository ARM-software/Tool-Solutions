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

PYTORCH_HASH=5ce4a8b49f9986b050a9f6fcc7dd4cf999baa509  # 2.10.0.dev20251112 from viable/strict, Nov 12th
IDEEP_HASH=927570638b237b0e39fb0626a868adffdbf70bbb    # From ideep_pytorch, October 20th
ONEDNN_HASH=80886d0559482dfe2019c2ae83eebd6d0d3a17d4   # From main, Nov 9th
TORCH_AO_HASH=17867e6788e4889b294449770f0275045384eab2 # From main, Nov 8th
KLEIDIAI_HASH=7bf4de9a56106f0fb0d57dfabeb4c7a2668deaf6 # v1.16.0 from main, Nov 10th

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    # Apply patches to PyTorch build
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/160184 - Draft: separate reqs for manywheel build and pin
    # Note: as part of this patch, setuptools is pinned to ~= 78.1.1 which is not affected by
    # CVE-2025-47273 and CVE-2024-6345
    apply-github-patch pytorch/pytorch 4d344570e5a114fa522e3370c5d59161e2ed8619

    # https://github.com/pytorch/pytorch/pull/167720 - Allow missing cutlass file if CUDA disabled
    apply-github-patch pytorch/pytorch 18f9ef2fe29b10b385f25eb6c98e3ac06227d2d9

    # https://github.com/pytorch/pytorch/pull/158250 - Integrate INT4→BF16 via KleidiAI, with fallback
    apply-github-patch pytorch/pytorch a9ec9d509167bfd33cbcd168cb40d183acf9c13a
    apply-github-patch pytorch/pytorch 67f1076366b88c6617256236020b58da00665ed4
    apply-github-patch pytorch/pytorch 99c57644d5d8a9359b6b98ac7bb96787ac594606
    apply-github-patch pytorch/pytorch a770fb9a9786d7ce39a3b066809fa8c0de7d47d5
    apply-github-patch pytorch/pytorch 30dd7406155c51b033b5e8a9c5a453fa59599db8
    apply-github-patch pytorch/pytorch 00b919af8e7bb50f52ec45fdad09304d4104464a
    apply-github-patch pytorch/pytorch fe40a60d7ad506aab016e66b53fdf0fc4f83b7a1
    apply-github-patch pytorch/pytorch 89fc01183127da738fc3723747f7bf0721fe9e09
    apply-github-patch pytorch/pytorch 23b4c39348426914cf3e6770dfaff0745245976c
    apply-github-patch pytorch/pytorch c5e778f5d4cac56b9d96f666c3082aab244e662f

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
