#!/bin/bash

# *******************************************************************************
# Copyright 2025 Arm Limited and affiliates.
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
    cd tensorflow
    git-bump nightly

    (
        cd third_party/mkl_dnn/oneDNN
        git-bump main
    )

    (
        cd third_party/compute_library/ComputeLibrary
        git-bump main
    )
)

echo "Put this into your get-sources.sh file"
echo TENSORFLOW_HASH=$(cd tensorflow && git rev-parse HEAD)
echo ONEDNN_HASH=$(cd tensorflow/third_party/mkl_dnn/oneDNN && git rev-parse HEAD)
echo ACL_HASH=$(cd tensorflow/third_party/compute_library/ComputeLibrary && git rev-parse HEAD)
