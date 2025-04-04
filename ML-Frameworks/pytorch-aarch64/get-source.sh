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
PYTORCH_HASH=114d404b0720e8073748690faeb96449e5c0b229  # torch-2.8.0.dev20250327 from viable/strict
IDEEP_HASH=719d8e6cd7f7a0e01b155657526d693acf97c2b3    # From ideep_pytorch
ONEDNN_HASH=5de25f354afee38bf2db61f485c729d30f62c611   # From main
ACL_HASH=9033bdacdc3840c80762bc56e8facb87b0e1048e      # 25.03 release
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    apply-github-patch pytorch/pytorch 143190 afded46b6c48fb434467cedacee4da956a66be64 # Enable AArch64 CI scripts to be used for local dev
    apply-github-patch pytorch/pytorch 150158 c868c903a8d5e3878bf1afc6159ca48c9d1ecad9 # Pin cmake version
    apply-github-patch pytorch/pytorch 140159 eb5c93062801320c5eb7e8b96b9a88721358858e # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch pytorch/pytorch 140159 48a32a05a56757dbd81ca112b04a01892115f811
    apply-github-patch pytorch/pytorch 140159 e1886a5f022ee9df5ad475a9463f6714289ff22d
    apply-github-patch pytorch/pytorch 140159 7d645531a9cf0b359182323e5b802e68f49af800
    apply-github-patch pytorch/pytorch 140159 e1abdb6d3eba957cdbd882bec21feeeb46550cf7
    apply-github-patch pytorch/pytorch 140159 4034f2538c4caafb806ecf4b2ef81b19ebda3fd6
    apply-github-patch pytorch/pytorch 140159 1ce26d99bde511bb9cccc49be842c04e8d366f69
    apply-github-patch pytorch/pytorch 150527 57b737db805acc5a58a6c9ef59dfef5b23aaf3f0 # Add BF16 SVE intrinsics

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD
        apply-github-patch intel/ideep 331 39e2de117c7470e7a8f8171603dd05d40b6943e1 # Cache reorder tensors
        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            apply-github-patch uxlfoundation/oneDNN 2838 f752a5392e3179829b60ca0d6aef08948da2abab # Dispatches fpmath_mode::bf16 conv to Compute Library
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
