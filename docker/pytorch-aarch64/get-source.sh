#!/bin/bash

# *******************************************************************************
# Copyright 2024 Arm Limited and affiliates.
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

set -eux -o pipefail

BUILDER_HASH=0015a521f4c1c003f6739be4d72bf503304fbf76 # From main
PYTORCH_HASH=3179eb15ae2ed08266392897ea18a498f91f8ba1 # From viable/strict
IDEEP_HASH=77d4b35c685eecfc8f32ced5381052483bdc3b1d   # From ideep_pytorch
ONEDNN_HASH=dd33e126c3607f25e14a8adb62c1eb0acc49488c  # From main
ACL_HASH=fa7806db5a2a9bf5c49b0ff3017cb9e8519dd440     # From main

function git-shallow-clone {
    (
        repo_name=$(basename "$1" .git)
        if ! cd "$repo_name" ; then
            echo "$repo_name doesn't exist, so we are making"
            mkdir "$repo_name"
            cd "$repo_name"
            git init
            git remote add origin $1
        fi
        git fetch --recurse-submodules=no origin $2
        # We do a force checkout + clean to overwrite previous patches
        git checkout -f $2
        git clean -f
    )
}

function apply-github-patch {
    # Apply a specific commit from a specific GitHub PR
    # $1 is PR url, $2 is commit hash
    set -u
    curl -L $1/commits/$2.patch | git apply
}

function apply-gerrit-patch {
    # $1 must be the url to a specific patch set
    # We get the repo by removing /c and chopping off the change number
    # e.g. https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1 -> https://review.mlplatform.org/ml/ComputeLibrary/
    repo_url=$(echo "$1" | sed 's#/c/#/#' | cut -d'+' -f1)
    # e.g. refs/changes/18/12818/1 Note that where the middle number is the last 2 digits of the patch number
    refname=$(echo "$1" | awk -F'/' '{print "refs/changes/" substr($(NF-1),length($(NF-1))-1,2) "/" $(NF-1) "/" $(NF)}')
    git fetch $repo_url $refname && git cherry-pick FETCH_HEAD
}

git-shallow-clone https://github.com/pytorch/builder.git $BUILDER_HASH
(
    cd builder
    apply-github-patch https://github.com/pytorch/builder/pull/2028 509c944589524708ae83634c9999117ababa7d0f # Enable AArch64 CI scripts to be used for local dev

    # Speed up the build by parallelizing. We could try to upstream this, but we would need to handle other platforms too
    # --ignore=1 so that we can have a core coordinating jobs
    sed -i -e 's/MAX_JOBS=5/MAX_JOBS=$(nproc --ignore=1)/g' aarch64_linux/aarch64_wheel_ci_build.py
)

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch
    # Bump OpenBLAS version. Note that install_openblas.sh has to be rerun in the PyTorch builder Docker container
    sed -i -e 's/v0.3.25/v0.3.28/g' .ci/docker/common/install_openblas.sh

    apply-github-patch https://github.com/pytorch/pytorch/pull/139887 eff3c11b1a31f725b50020ce32f6eddba17b5a94 # Use s8s8s8 for qlinear on aarch64 instead of u8s8u8 with mkl-dnn
    apply-github-patch https://github.com/pytorch/pytorch/pull/139753 16d397416abc44005fc66e377d4d15a0d6131a32 # Add SVE implementation for 8 bit quantized embedding bag on aarch64
    apply-github-patch https://github.com/pytorch/pytorch/pull/136850 6d5aaff8434203f870d76d840158d6989ddd61d0 # Enable XNNPACK for quantized add
    apply-github-patch https://github.com/pytorch/pytorch/pull/140233 6d0b4448bfe3771e076e5c7758333f98810605c4 # Enables static quantization for aarch64
    apply-github-patch https://github.com/pytorch/pytorch/pull/135058 511af4efb5c008a75a196c525a7ad546a9915fd0 # Pass ideep:lowp_kind to matmul_forward::compute on cache misses
    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD
        apply-github-patch https://github.com/intel/ideep/pull/331 39e2de117c7470e7a8f8171603dd05d40b6943e1 # Cache reorder tensors
        apply-github-patch https://github.com/intel/ideep/pull/341 120bf1920cc126f3ee28c20a93b0013799b74339 # Include hash of weights in the key of the primitive cache for aarch64 lowp gemm
        (
            cd mkl-dnn
            git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD
            apply-github-patch https://github.com/oneapi-src/oneDNN/pull/2194 c22f4ae50002ef0a93bfe1895684f36abd92517d # src: cpu: aarch64: lowp_matmul: Make weights constant
            # Two commits from one PR
            apply-github-patch https://github.com/oneapi-src/oneDNN/pull/2198 6a77e84feb442964c91a0101d58fe1473566b185 # src: cpu: aarch64: Enable matmul static quantisation.
            apply-github-patch https://github.com/oneapi-src/oneDNN/pull/2198 efad4f6582c13823d81c78130ab80db57b1381eb # src: cpu: aarch64: Enable convolution static quantisation.

            apply-github-patch https://github.com/oneapi-src/oneDNN/pull/2212 0358abf98dd6c5221a0c40ea47f0a23a1e6cf28e # src: cpu: aarch64: lowp_matmul: Make weights constant
        )
    )
)

git-shallow-clone https://review.mlplatform.org/ml/ComputeLibrary $ACL_HASH
(
    cd ComputeLibrary
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1 # perf: Improve gemm_interleaved 2D vs 1D blocking heuristic
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12819/1 # fix: Do not skip prepare stage after updating quantization parameters
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12820/3 # fix: Do not skip MatrixBReduction in prepare for dynamic offsets
    apply-gerrit-patch https://review.mlplatform.org/c/ml/ComputeLibrary/+/12904/2 # fix: incorrect scheduling hint heuristic for GEMMs
)
