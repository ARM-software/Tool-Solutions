#!/bin/bash

# *******************************************************************************
# Copyright 2024-2025 Arm Limited and affiliates.
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

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=65781570c55d2338106767de200323f123c3f91f

# The next oneDNN commits relocate xbyak_aarch64 as a third_party module,
# but this is not picked up by TF Bazel build.
ONEDNN_HASH=ad06da68524b2b5e63fc1d7a7a749d555394a0a7       # main Jan 03, 2025
 
# The next ACL commit introduces KleidiAI as a third-party module,
# but this is not picked up by TF Bazel build.
ACL_HASH=0038c52d6c79b76755c087cda1be4bbf752e272c          # main Jan 6, 2025

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH

(
    cd tensorflow

    # Apply TensorFlow WIP patches here

    apply-github-patch tensorflow/tensorflow 6eb08485a6312a02636f79d8eddf00a549e32aca # build(aarch64): Update to oneDNN-3.7 + ACL-24.12 (fix)

)
