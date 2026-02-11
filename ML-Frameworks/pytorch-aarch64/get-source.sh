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

    # https://github.com/pytorch/pytorch/pull/167829 - Refactor ACL and OpenBLAS install scripts on AArch64
    apply-github-patch pytorch/pytorch f5e7b3ab44b14902f1e44ac138006b04bd9b7728

    # https://github.com/pytorch/pytorch/pull/170062 - Add ccache support to ACL/OpenBLAS and manywheel
    # build script.
    apply-github-patch pytorch/pytorch 327b118078869b85d979d9f7eb1038b8a53c8a49

    # https://github.com/pytorch/pytorch/pull/170600 - Gate deletion of clean-up steps in build_common.sh
    apply-github-patch pytorch/pytorch e368ec2693b8b2b8ba35d0913f1d663ba2fdc804

    # FIXME: Temporarily disabled; to be updated in a later PR
    # # https://github.com/pytorch/pytorch/pull/160184 - Draft: separate reqs for manywheel build and pin
    # # Note: as part of this patch, setuptools is pinned to ~= 78.1.1 which is not affected by
    # # CVE-2025-47273 and CVE-2024-6345
    # apply-github-patch pytorch/pytorch 4d344570e5a114fa522e3370c5d59161e2ed8619

    # https://github.com/pytorch/pytorch/pull/167720 - Allow missing cutlass file if CUDA disabled
    apply-github-patch pytorch/pytorch 6fbbfe712d89895824e466a4e3ae6a0f35626078

    # https://github.com/pytorch/pytorch/pull/159859 - PoC LUT optimisation for GELU bf16 operators
    apply-github-patch pytorch/pytorch ebcc874e317f9563ab770fc5c27df969e0438a5e

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
    # fbgemm/fbgemm_gpu/experimental/gen_ai has moved to the 'mslk' repo. Get rid of it
    git rm third_party/mslk

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

git-shallow-clone https://github.com/pytorch/ao.git $TORCH_AO_HASH
(
    # Remove cutlass directory
    cd ao
    git rm third_party/cutlass
)
