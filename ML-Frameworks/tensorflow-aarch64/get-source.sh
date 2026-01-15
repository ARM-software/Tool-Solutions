#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=20c4833e3b81d1aa947643da899b8fb512d22e36 # from nightly, Jan 11th

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH

(
    cd tensorflow

    # Apply TensorFlow WIP patches here

    # https://github.com/tensorflow/tensorflow/pull/100882 - build(aarch64): Update Compute Library to 52.4.0
    apply-github-patch tensorflow/tensorflow 33a28c399c24ed03e94bd8d8fee289f67946fc7b
    # https://github.com/tensorflow/tensorflow/pull/102272 - Fix AArch64 CPUIDInfo init
    apply-github-patch tensorflow/tensorflow b6a9e1c1173d675533ffbb71c5eb36c7060ae2d0
)
