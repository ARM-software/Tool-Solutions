#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=3d4958d107b77a2e4398c066971a099a369ef739 # from nightly, Feb 2nd

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH

(
    cd tensorflow

    # Apply TensorFlow WIP patches here

    # https://github.com/tensorflow/tensorflow/pull/100882 - build(aarch64): Update Compute Library to 52.4.0
    apply-github-patch tensorflow/tensorflow f15bec785f25dacaf9ae18250e499274e4ec7fb1
    # https://github.com/tensorflow/tensorflow/pull/102272 - Fix AArch64 CPUIDInfo init
    apply-github-patch tensorflow/tensorflow b6a9e1c1173d675533ffbb71c5eb36c7060ae2d0
)
