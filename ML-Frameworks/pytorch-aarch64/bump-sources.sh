#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

function git-bump {
    git fetch origin $1
    # Clean up any patches
    git checkout -- .
    git reset --hard origin/$1
    echo "Bumped to:"
    git log -1
}

(
    cd pytorch
    git-bump viable/strict

    git submodule sync
    git submodule update --init --checkout --force --recursive --jobs=$(nproc)
    (
        cd third_party/ideep
        git-bump ideep_pytorch
        (
            cd mkl-dnn
            git-bump main
        )
    )
)

echo "Put this into your get-sources.sh file"
echo PYTORCH_HASH=$(cd pytorch && git rev-parse HEAD)
echo IDEEP_HASH=$(cd pytorch/third_party/ideep && git rev-parse HEAD)
echo ONEDNN_HASH=$(cd pytorch/third_party/ideep/mkl-dnn && git rev-parse HEAD)
