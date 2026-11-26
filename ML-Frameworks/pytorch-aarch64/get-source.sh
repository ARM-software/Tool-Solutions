#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh
source ./versions.sh

set -eux -o pipefail

source_variant=patched

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source-variant)
            if [[ $# -lt 2 ]]; then
                >&2 echo "error: --source-variant requires a value"
                exit 1
            fi
            source_variant="$2"
            shift 2
            ;;
        --source-variant=*)
            source_variant="${1#*=}"
            shift
            ;;
        *)
            >&2 echo "error: unknown option '$1'"
            exit 1
            ;;
    esac
done

case "$source_variant" in
    upstream|pinned|patched) ;;
    *)
        >&2 echo "error: invalid --source-variant '$source_variant'"
        >&2 echo "valid values: upstream, pinned, patched"
        exit 1
        ;;
esac

git-shallow-clone https://github.com/pytorch/pytorch.git $PYTORCH_HASH
(
    cd pytorch

    # Apply patches to PyTorch
    if [[ "$source_variant" != patched ]]; then
        echo "Not applying extra patches to PyTorch build for source variant '$source_variant'"
    else
        # https://github.com/pytorch/pytorch/pull/193369 - Enable a reference CPU MXFP scaled_mm path
        apply-github-patch pytorch/pytorch 5355dbb998343f137d0959e55af245ec8a06f88a
        apply-github-patch pytorch/pytorch 98a4bb017aab394d4788ad2a82d8e3309d2e39d7
        apply-github-patch pytorch/pytorch 791e25280f4a34de8f89c3f07ae6cf7b1c98dc89

        # https://github.com/pytorch/pytorch/pull/184372 - [Draft] Remove ACL
        apply-github-patch pytorch/pytorch 1b1f3c78fa42ca3733eac24b43a89df134518ace

        # https://github.com/pytorch/pytorch/pull/196435 - Replace Linear inner_product calls with matmul
        apply-github-patch pytorch/pytorch ac57d46fc92c701e83c232230378f3f6a91bbc67

        # https://github.com/pytorch/pytorch/pull/206798 - Preserve copy-on-write weights and biases in oneDNN Linear
        apply-github-patch pytorch/pytorch de149d2b71ef1c7d0076871027a6fdfe84edc2cb

        # https://github.com/pytorch/pytorch/pull/206684 - Fix zero-stride gradients in oneDNN GELU backward
        apply-github-patch pytorch/pytorch d52880991949d9555eafa6d14fff6648930ceed7
    fi

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

    # Fetch desired version of ideep/oneDNN/KleidiAI
    if [[ "$source_variant" == upstream ]]; then
        echo "Using PyTorch's upstream submodule hashes for ideep, oneDNN, and KleidiAI for source variant '$source_variant'"
    else
        (
            cd third_party/ideep
            git fetch origin $IDEEP_HASH && git clean -f && git checkout -f FETCH_HEAD

            (
                cd mkl-dnn
                git fetch origin $ONEDNN_HASH && git clean -f && git checkout -f FETCH_HEAD

                if [[ "$source_variant" != patched ]]; then
                    echo "Not applying extra patches to oneDNN build for source variant '$source_variant'"
                else
                    # https://github.com/uxlfoundation/oneDNN/pull/5156 - cpu: aarch64: replace acl with kleidiai
                    apply-github-patch uxlfoundation/oneDNN aa471b53ff24dfc5eeacb5de0b4d6b476129a208
                    apply-github-patch uxlfoundation/oneDNN ad3fb910575ec142665a4e7e42e5777359575488
                    apply-github-patch uxlfoundation/oneDNN ef0a1218801c8c715c7be5fe499aab273cbaf3b2
                    apply-github-patch uxlfoundation/oneDNN d2a8a3d114c8af83e98dcbd930c8ff5743689101
                    apply-github-patch uxlfoundation/oneDNN bb239310f91fa1ee4f9c53b911ac86f2c1a4a5d8
                    apply-github-patch uxlfoundation/oneDNN 3559154b042d320e20b55c8473e3253e70144c8f
                    apply-github-patch uxlfoundation/oneDNN 795878ff401032d5f53ef530240618c4c7b921c7
                    apply-github-patch uxlfoundation/oneDNN eda9f9d2be04311cec586a14db0cd1dd0e7c9aae

                    # https://github.com/uxlfoundation/oneDNN/pull/6202 - cpu: aarch64: Preserve the precomputed input contribution in BRGEMM LSTM
                    apply-github-patch uxlfoundation/oneDNN 3767f886ee6a7cf002dac33e305d25a7d836a26a
                fi
            )
        )
        (
            cd third_party/kleidiai
            git fetch origin $KLEIDIAI_HASH && git clean -f && git checkout -f FETCH_HEAD
        )
    fi
)
