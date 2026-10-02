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
        apply-github-patch pytorch/pytorch e2c390d3c2413434fb5f9564681ee276315fd600
        apply-github-patch pytorch/pytorch ee3d7365af619245970121b7e78cb91d3ee3bce1
        apply-github-patch pytorch/pytorch 022eb85860279f6c81ebd6ff4108c0ea0896c12b

        # https://github.com/pytorch/pytorch/pull/184372 - [Draft] Remove ACL
        apply-github-patch pytorch/pytorch c571509944f87598ded77fa184462fe074cfc8c5
        apply-github-patch pytorch/pytorch 6fdf90160e24cefcfa7e22e9bccb3e8a0e7019e7

        # https://github.com/pytorch/pytorch/pull/196237 - [inductor] Support Triton module globals in user-defined kernels
        apply-github-patch pytorch/pytorch 1e17023ce4f8ea329dcfbef438f9cab18210b362

        # https://github.com/pytorch/pytorch/pull/196435 - Replace Linear inner_product calls with matmul
        apply-github-patch pytorch/pytorch 6588e8f43a50816684e570f37475591d68ebce28
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
                    apply-github-patch uxlfoundation/oneDNN 59e4143c2d47f3347b2574946200ea95812b988e
                    apply-github-patch uxlfoundation/oneDNN 1b8417b74701753089a063415b03c852e2aed4f8
                    apply-github-patch uxlfoundation/oneDNN 341943b3d423762385c3733b2392a3829dde5344
                    apply-github-patch uxlfoundation/oneDNN 44ec824dfcab928947d9cfa3e7110d087c3932bc
                    apply-github-patch uxlfoundation/oneDNN 294a037ddbd7942ac23ce0859dd05537106c9175
                    apply-github-patch uxlfoundation/oneDNN 12765c5ff27aeae1e8cc86edda6c68450f94e326
                    apply-github-patch uxlfoundation/oneDNN 6378bc0fe9f6ef254e92e006b224508444727fcf

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
