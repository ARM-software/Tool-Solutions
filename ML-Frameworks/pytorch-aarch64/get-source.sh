#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh
source ./versions.sh

set -eux -o pipefail

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    # Apply patches to PyTorch build
    cd pytorch

    # https://github.com/pytorch/pytorch/pull/182655 - Update ACL/OpenBLAS/manywheel build scripts and add ccache support
    apply-github-patch pytorch/pytorch 159406ab7f210bacadb757fabef28ac9ddacb706

    # https://github.com/pytorch/pytorch/pull/170600 - Gate deletion of clean-up steps in build_common.sh
    apply-github-patch pytorch/pytorch e368ec2693b8b2b8ba35d0913f1d663ba2fdc804

    # https://github.com/pytorch/pytorch/pull/167328 - Build cpuinfo into c10 shared library
    apply-github-patch pytorch/pytorch 7c053dd1582b778c81101dd452708c4ec6e58233
    apply-github-patch pytorch/pytorch b1782bbe0eda5957870e2f6e95b8f167e04843cb
    apply-github-patch pytorch/pytorch 337925aed2babb3ef7808f78536bbbc9df346a4f

    # https://github.com/pytorch/pytorch/pull/177867 - Add ASIMD_BF16 Vectorized class specialisation
    apply-github-patch pytorch/pytorch 6cbed7b8e0d5985569b4cc36931afc717930fe00
    apply-github-patch pytorch/pytorch 6e6878ec8869fd8f7d9314571a3e84933f149ef5
    apply-github-patch pytorch/pytorch e14a2184c44c96e433f468ba12e104dc6be85886

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
    # fbgemm/fbgemm_gpu/experimental/gen_ai has moved to the 'mslk' repo. Get rid of it
    git rm third_party/mslk
    # This third-party folder contains just a license to cover libomp from the LLVM project
    # which is not present in our torch build; it contains libgomp
    git rm -r third_party/llvm-openmp

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
