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
PYTORCH_HASH=62ce3e6e84df516fdd5310d5095fa01251806f1d   # From viable/strict
IDEEP_HASH=9873ffca18467b07f4fb6cbbd8742dc7c6588b72     # From ideep_pytorch
ONEDNN_HASH=283cf3783c28c231308f13cf2c6a0247517f934f    # From main
ACL_HASH=d9be9625ca86ebefcd171d049273d2ee295737a0       # From main
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307  # From main
KLEIDI_AI_HASH=ef685a13cfbe8d418aa2ed34350e21e4938358b6 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    apply-github-patch https://github.com/pytorch/pytorch 143190 f424c67660f45bfeaceb9bebfafc7e22638746c4 # Enable AArch64 CI scripts to be used for local dev

    apply-github-patch https://github.com/pytorch/pytorch 145486 bd314eef0cb371607e714b3519f5564938490f4a # feat: add SVE dispatch for non-FBGEMM qembeddingbag (fixes illigal instruction failures on N1)
    apply-github-patch https://github.com/pytorch/pytorch 139887 eff3c11b1a31f725b50020ce32f6eddba17b5a94 # Use s8s8s8 for qlinear on aarch64 instead of u8s8u8 with mkl-dnn
    apply-github-patch https://github.com/pytorch/pytorch 136850 6d5aaff8434203f870d76d840158d6989ddd61d0 # Enable XNNPACK for quantized add
    apply-github-patch https://github.com/pytorch/pytorch 142391 8373846f441381a56e7abd905af84102aa52fc7b # parallelize sort
    apply-github-patch https://github.com/pytorch/pytorch 140159 8d3404ec5972528f606fe605887ad2254a174fbc # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch https://github.com/pytorch/pytorch 140159 ab4c191ef0de1e4eced6b4dd7b6e387f57034ad9 # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch https://github.com/pytorch/pytorch 140159 879ca72d54559a388db315eed40803d2f1c827b7 # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch https://github.com/pytorch/pytorch 140159 150f5d92fa79a57a580ac000f667d05787b650b3 # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch https://github.com/pytorch/pytorch 145942 3d05899222da2b93ed3d4c88c382d318e68eeec6 # Enable fast qlinear_dynamic path for AArch64 through Arm Compute Library directly
    apply-github-patch https://github.com/pytorch/pytorch 141127 3f2fad0b4774126f228597ba03b68a472fc433cc # Enables static quantization for aarch64
    apply-github-patch https://github.com/pytorch/pytorch 143666 8e5134e9c22cdb6150e425bee43015998ae55c59 # Extend Vec backend with SVE BF16
    apply-github-patch https://github.com/pytorch/pytorch 143666 5e73650463396c7f09e4d0c928a3f72a2cecf306 # Extend Vec backend with SVE BF16
    apply-github-patch https://github.com/pytorch/pytorch 143666 6e21cd41667e63b5c534ca87d8590e781b3f0f06 # Extend Vec backend with SVE BF16
    apply-github-patch https://github.com/pytorch/pytorch 146476 7f7782494e82ed76986716e58205c033809cca70 # Improve KleidiAI 4 bit kernel performance

    # Submodules needs to be handled manually for patches that adds submodules
    setup_submodule https://git.gitlab.arm.com/kleidi/kleidiai.git third_party/kleidiai $KLEIDI_AI_HASH

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD
        apply-github-patch https://github.com/intel/ideep 331 39e2de117c7470e7a8f8171603dd05d40b6943e1 # Cache reorder tensors
        apply-github-patch https://github.com/intel/ideep 341 120bf1920cc126f3ee28c20a93b0013799b74339 # Include hash of weights in the key of the primitive cache for aarch64 lowp gemm
        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            apply-github-patch https://github.com/oneapi-src/oneDNN 2194 c22f4ae50002ef0a93bfe1895684f36abd92517d # src: cpu: aarch64: lowp_matmul: Make weights constant
            apply-github-patch https://github.com/oneapi-src/oneDNN 2212 3e4904106682369d9661350b97fc316e0a0edcbf # src: cpu: aarch64: lowp_matmul: Make weights constant
            apply-github-patch https://github.com/oneapi-src/oneDNN 2502 49ac258a43520562a196ba081a3c259ac3732df2 # cpu: aarch64: ip: Allow bf16 for ACL inner product
        )
    )
)

git-shallow-clone https://review.mlplatform.org/ml/ComputeLibrary $ACL_HASH
(
    cd ComputeLibrary
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/13445/3 # feat: Enable BF16 inputs in CpuFullyConnected
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1 # perf: Improve gemm_interleaved 2D vs 1D blocking heuristic
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12819/1 # fix: Do not skip prepare stage after updating quantization parameters
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12820/3 # fix: Do not skip MatrixBReduction in prepare for dynamic offsets
)

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
(
    cd ao
    apply-github-patch https://github.com/pytorch/ao 1447 738d7f2c5a48367822f2bf9d538160d19f02341e # [Feat]: Add support for kleidiai quantization schemes
)
