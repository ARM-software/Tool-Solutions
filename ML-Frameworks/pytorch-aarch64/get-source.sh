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
        # Disable the sudo commands in the manywheel build which restart the Docker daemon
        replace_once .ci/docker/manywheel/build.sh \
            'if [ "$(uname -m)" != "s390x" ] && [ -v CI ]; then' \
            'if false; then'
        git add .ci/docker/manywheel/build.sh
        git-with-credentials commit -m "Disable sudo commands in manywheel build"

        # # https://github.com/pytorch/pytorch/pull/182655 - Update ACL/OpenBLAS/manywheel build scripts and add ccache support
        # apply-github-patch pytorch/pytorch 159406ab7f210bacadb757fabef28ac9ddacb706

        # # https://github.com/pytorch/pytorch/pull/170600 - Gate deletion of clean-up steps in build_common.sh
        # apply-github-patch pytorch/pytorch e368ec2693b8b2b8ba35d0913f1d663ba2fdc804

        # # https://github.com/pytorch/pytorch/pull/167328 - Build cpuinfo into c10 shared library
        # apply-github-patch pytorch/pytorch 7c053dd1582b778c81101dd452708c4ec6e58233
        # apply-github-patch pytorch/pytorch b1782bbe0eda5957870e2f6e95b8f167e04843cb
        # apply-github-patch pytorch/pytorch 337925aed2babb3ef7808f78536bbbc9df346a4f

        # https://github.com/pytorch/pytorch/pull/184372 - [Draft] Remove ACL
        apply-github-patch pytorch/pytorch 0b0d4ac70463892391dcacde63d087e8fa1c980d
        apply-github-patch pytorch/pytorch 30788230c5dcdd2a2a716c7cf4aa7530615ffe89
        apply-github-patch pytorch/pytorch 129cc717fa87f733aa41b4807bac399c94c2057c
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
                    apply-github-patch uxlfoundation/oneDNN 9d2436344f2cecb2ac2f879a2ffbbcc27cbe2aaf
                    apply-github-patch uxlfoundation/oneDNN 685713adc27e3a34d6265f9e4cfd2eb3541ed6be
                    apply-github-patch uxlfoundation/oneDNN c0dec6ea825430977b23773547a62310ab806cea
                    git submodule update --init third_party/kleidiai
                fi
            )
        )
        (
            cd third_party/kleidiai
            git fetch origin $KLEIDIAI_HASH && git clean -f && git checkout -f FETCH_HEAD
        )
    fi
)
