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

PYTORCH_HASH=8d4926e30a944320adf434016129cb6788eff79b  # From viable/strict
IDEEP_HASH=e026f3b0318087fe19e2b062e8edf55bfe7a522c    # From ideep_pytorch
ONEDNN_HASH=0fd3b73a25d11106e141ddefd19fcacc74f8bbfe   # From main
ACL_HASH=6acccf1730b48c9a22155998fc4b2e0752472148      # From main
TORCH_AO_HASH="2e032c6b0de960dee554dcb08126ace718b14c6d" # From main

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
    # $1 is the repo url, $2 is the PR number, and $3 is commit hash
    set -u

    # Look in the PR first
    curl --silent -L $1/pull/$2/commits/$3.patch -o $3.patch

    # If the PR has been updated, the commit may no longer be there and the .patch will be empty.
    # Look in the full repo instead.
    # If it can't be found, this time curl will error
    if [[ ! -s $3.patch ]]; then
       >&2 echo "Commit $3 not found in $1/pull/$2. Checking the full repository..."
       curl --silent --fail -L $1/commit/$3.patch -o $3.patch
    fi

    # Apply the patch and tidy up.
    patch -p1 < $3.patch
    rm $3.patch
    return 0
}

function apply-gerrit-patch {
    # $1 must be the url to a specific patch set
    # We get the repo by removing /c and chopping off the change number
    # e.g. https://review.mlplatform.org/c/ml/ComputeLibrary/+/12818/1 -> https://review.mlplatform.org/ml/ComputeLibrary/
    repo_url=$(echo "$1" | sed 's#/c/#/#' | cut -d'+' -f1)
    # e.g. refs/changes/18/12818/1 Note that where the middle number is the last 2 digits of the patch number
    refname=$(echo "$1" | awk -F'/' '{print "refs/changes/" substr($(NF-1),length($(NF-1))-1,2) "/" $(NF-1) "/" $(NF)}')
    git fetch $repo_url $refname && git cherry-pick --no-commit FETCH_HEAD
}

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch
    # Bump OpenBLAS version. Note that install_openblas.sh has to be rerun in the PyTorch builder Docker container
    sed -i -e 's/v0.3.25/v0.3.28/g' .ci/docker/common/install_openblas.sh

    apply-github-patch https://github.com/pytorch/pytorch 143190 bdb74e24bfc70240fd2260dd7613246d7972fac1 # Enable AArch64 CI scripts to be used for local dev

    apply-github-patch https://github.com/pytorch/pytorch 139887 eff3c11b1a31f725b50020ce32f6eddba17b5a94 # Use s8s8s8 for qlinear on aarch64 instead of u8s8u8 with mkl-dnn
    apply-github-patch https://github.com/pytorch/pytorch 139753 16d397416abc44005fc66e377d4d15a0d6131a32 # Add SVE implementation for 8 bit quantized embedding bag on aarch64
    apply-github-patch https://github.com/pytorch/pytorch 136850 6d5aaff8434203f870d76d840158d6989ddd61d0 # Enable XNNPACK for quantized add
    apply-github-patch https://github.com/pytorch/pytorch 140233 6d0b4448bfe3771e076e5c7758333f98810605c4 # Enables static quantization for aarch64
    apply-github-patch https://github.com/pytorch/pytorch 135058 511af4efb5c008a75a196c525a7ad546a9915fd0 # Pass ideep:lowp_kind to matmul_forward::compute on cache misses
    apply-github-patch https://github.com/pytorch/pytorch 142391 8373846f441381a56e7abd905af84102aa52fc7b # parallelize sort
    apply-github-patch https://github.com/pytorch/pytorch 139387 e5e5d29d6bab882540e36e44a3a75bd187fcbb62 # Add prepacking for linear weights
    apply-github-patch https://github.com/pytorch/pytorch 139387 19423aaa1af154e1d47d8acf1e677dff727da5aa # Add prepacking for linear weights
    apply-github-patch https://github.com/pytorch/pytorch 140159 10d3e48f6172f18e36ba568e2760f39b31a13e1d # cpu: aarch64: enable gemm-bf16f32
    apply-github-patch https://github.com/pytorch/pytorch 134124 1c0ef38138d8621ab4a044860404fbf01c7504a6 # [ARM][feat]: Add 4 bit dynamic quantization matmuls & KleidiAI Backend
    apply-github-patch https://github.com/pytorch/pytorch 134124 80d263f5343806d3169f5c180f23cfe975264bdf # [ARM][feat]: Add 4 bit dynamic quantization matmuls & KleidiAI Backend
    apply-github-patch https://github.com/pytorch/pytorch 134124 3c10c2b55eecd2f9316b845ff697519639601527 # [ARM][feat]: Add 4 bit dynamic quantization matmuls & KleidiAI Backend
    apply-github-patch https://github.com/pytorch/pytorch 134124 6d178afd7d82d2ed12b7734e7e2b350a2d332e1c # [ARM][feat]: Add 4 bit dynamic quantization matmuls & KleidiAI Backend

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
            # Multiple commits from one PR
            apply-github-patch https://github.com/oneapi-src/oneDNN 2212 6a77e84feb442964c91a0101d58fe1473566b185 # src: cpu: aarch64: Enable matmul static quantisation.
            apply-github-patch https://github.com/oneapi-src/oneDNN 2212 efad4f6582c13823d81c78130ab80db57b1381eb # src: cpu: aarch64: Enable convolution static quantisation.
            apply-github-patch https://github.com/oneapi-src/oneDNN 2212 0358abf98dd6c5221a0c40ea47f0a23a1e6cf28e # src: cpu: aarch64: lowp_matmul: Make weights constant

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

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
(
    cd ao
    apply-github-patch https://github.com/pytorch/ao.git 1447 738d7f2c5a48367822f2bf9d538160d19f02341e # [Feat]: Add support for kleidiai quantization schemes
)
