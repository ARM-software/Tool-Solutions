#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=fff60aa253b3d2a3cb9e0e988e72cdab761530d1 # from nightly, May 28th

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH

(
    cd tensorflow

    # Apply TensorFlow WIP patches here

    # https://github.com/tensorflow/tensorflow/pull/113368 - Bump Compute Library version from v24.12 to v52.8.0
    apply-github-patch tensorflow/tensorflow 189698cf3b3dab5375508ff2e02f6aba3a586323
    # https://github.com/tensorflow/tensorflow/pull/102272 - Fix AArch64 CPUIDInfo init
    apply-github-patch tensorflow/tensorflow b6a9e1c1173d675533ffbb71c5eb36c7060ae2d0
)
