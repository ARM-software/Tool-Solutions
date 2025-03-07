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
PYTORCH_He555c4d8ae6f8b0f6d21072a4559b6154c8c19eb  # 2.7.0.dev20250305 from viable/strict
IDEEP_HASH=719d8e6cd7f7a0e01b155657526d693acf97c2b3    # From ideep_pytorch
ONEDNN_HASH=321c4520924af264518159777f21f630075c9b71   # From main
ACL_HASH=534f1c5aee4dc97794a6772a8215708abc1f1e52      # 25.02.1 release
TORCH_AO_HASH=e1cb44ab84eee0a3573bb161d65c18661dc4a307 # From main

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    apply-github-patch https://github.com/pytorch/pytorch 143190 afded46b6c48fb434467cedacee4da956a66be64 # Enable AArch64 CI scripts to be used for local dev
    apply-github-patch https://github.com/pytorch/pytorch 140159 8d3404ec5972528f606fe605887ad2254a174fbc # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch https://github.com/pytorch/pytorch 140159 ab4c191ef0de1e4eced6b4dd7b6e387f57034ad9
    apply-github-patch https://github.com/pytorch/pytorch 140159 879ca72d54559a388db315eed40803d2f1c827b7
    apply-github-patch https://github.com/pytorch/pytorch 140159 150f5d92fa79a57a580ac000f667d05787b650b3
    apply-github-patch https://github.com/pytorch/pytorch 148542 99e5d35a460413da5a8976bef0b65babcdf95fc3 # Enable Direct Use of Arm Compute Library (ACL) in ATen
    apply-github-patch https://github.com/pytorch/pytorch 147337 ac5618b6bc1d522f8e944b6567a74905af315fd9 # Enable a fast path for (static) qlinear for AArch64 through ACL directly
    apply-github-patch https://github.com/pytorch/pytorch 147337 0b06ae118c19af5551c4c638c88abdf959ec8a3f
    apply-github-patch https://github.com/pytorch/pytorch 146620 a0d20465a0590ecb79e7a8e2101145a223f89f36 # Enable qint8 and quint8 add for AArch64 using ACL directly
    apply-github-patch https://github.com/pytorch/pytorch 148197 e2efe476c1162986eb16132cf6000be3ef9c211e # Enable oneDNN dispatch for gemm bf16bf16->bf16
    apply-github-patch https://github.com/pytorch/pytorch 143666 4903aefc81145056ac5cc41cb5568dc61b03aca1 # Extend vec backend with BF16 SVE intrinsics
    apply-github-patch https://github.com/pytorch/pytorch 143666 7c93930e5031cb964a17683f0b0bd965f1486f37
    apply-github-patch https://github.com/pytorch/pytorch 143666 ec27f37b032a537075b0870750adae48c3f09e61
    apply-github-patch https://github.com/pytorch/pytorch 143666 c063ac24cc582da05871b6c7a7c7e33b0b08e097
    apply-github-patch https://github.com/pytorch/pytorch 143666 a632a1fb34fcc28ef98ab27a6041950f976bf475
    apply-github-patch https://github.com/pytorch/pytorch 143666 03fca5494b1019514f7400c8737a57b6b8234773
    apply-github-patch https://github.com/pytorch/pytorch 143666 17a346fab23182c0efade9fea982f5b8d45112f1
    apply-github-patch https://github.com/pytorch/pytorch 143666 6ca8ed8d8fe58488e2896b57b99c24b21fc6c50b
    apply-github-patch https://github.com/pytorch/pytorch 143666 c3341033261e46aa818444ceff9838eded8f71b2
    apply-github-patch https://github.com/pytorch/pytorch 143666 00f0dc0fce51612fe7315653870e6528c3375092

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD
        apply-github-patch https://github.com/intel/ideep 331 39e2de117c7470e7a8f8171603dd05d40b6943e1 # Cache reorder tensors
        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
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
    apply-github-patch https://github.com/pytorch/ao 1447 738d7f2c5a48367822f2bf9d538160d19f02341e # [Feat]: Add support for kleidiai quantization schemes
)
