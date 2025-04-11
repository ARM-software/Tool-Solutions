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
PYTORCH_HASH=fc674b45d4d8edfd4c630d89f71ea9f85a2f61f2  # 2.8.0.dev20250403 from viable/strict
IDEEP_HASH=719d8e6cd7f7a0e01b155657526d693acf97c2b3    # From ideep_pytorch
ONEDNN_HASH=5de25f354afee38bf2db61f485c729d30f62c611   # From main
ACL_HASH=9033bdacdc3840c80762bc56e8facb87b0e1048e      # 25.03 release
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    apply-github-patch pytorch/pytorch 143190 afded46b6c48fb434467cedacee4da956a66be64 # Enable AArch64 CI scripts to be used for local dev
    apply-github-patch pytorch/pytorch 140159 d5aeab452e4b1f0580a4636b15a604c77a02c57b # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch pytorch/pytorch 140159 a96100e948f16ca2a10689b260adfd4e3dae5709
    apply-github-patch pytorch/pytorch 150527 57b737db805acc5a58a6c9ef59dfef5b23aaf3f0 # Add BF16 SVE intrinsics
    apply-github-patch pytorch/pytorch 143666 369c3b7dbe22c7b1d96d94ef59366e383ff71bd1
    apply-github-patch pytorch/pytorch 150833 02987a7c2e9b249a669723224c8d3cd80c6cb64e # Pin all root requirements to major versions

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD
        apply-github-patch intel/ideep 331 39e2de117c7470e7a8f8171603dd05d40b6943e1 # Cache reorder tensors
        apply-github-patch intel/ideep 354 8c51b8fed7526d38dc6998d9ef9d45cc7629a1f6 # revert explicit reorder for eltwise for bf16
        apply-github-patch intel/ideep 354 6c73e070241bb0ff5a877969540b432720fbd55e

        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            apply-github-patch uxlfoundation/oneDNN 2838 f752a5392e3179829b60ca0d6aef08948da2abab # Dispatches fpmath_mode::bf16 conv to Compute Library
            apply-github-patch uxlfoundation/oneDNN 3022 4a00e92b995388192e666ee332554e4ef65b484a # cpu: aarch64: enable jit conv for 128
            apply-github-patch uxlfoundation/oneDNN 2982 bf4bcdc3d28b7e30a8b184dcad661e6975d8ae3a # cpu: aarch64: enable eltwise bf16  (via f32 conversion)
            apply-github-patch uxlfoundation/oneDNN 2982 097afe4f6e161568ac222b98e869be48248bdf6b
            apply-github-patch uxlfoundation/oneDNN 2982 0c3a3f06ed902017c5dd26fab1022aa4e4b67516
        )
    )
)

git-shallow-clone https://review.mlplatform.org/ml/ComputeLibrary $ACL_HASH
(
    cd ComputeLibrary
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1 # perf: Improve gemm_interleaved 2D vs 1D blocking heuristic
)

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
(
    cd ao
    apply-github-patch pytorch/ao 1447 738d7f2c5a48367822f2bf9d538160d19f02341e # [Feat]: Add support for kleidiai quantization schemes
)
