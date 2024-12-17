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

(
    cd ComputeLibrary
    git-bump main
)

echo "Put this into your get-sources.sh file"
echo PYTORCH_HASH=$(cd pytorch && git rev-parse HEAD)
echo IDEEP_HASH=$(cd pytorch/third_party/ideep && git rev-parse HEAD)
echo ONEDNN_HASH=$(cd pytorch/third_party/ideep/mkl-dnn && git rev-parse HEAD)
echo ACL_HASH=$(cd ComputeLibrary && git rev-parse HEAD)
