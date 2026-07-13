#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=7fd0883713c3c95b4ace0a637de461c731c1db1d # from nightly, July 7th

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH

(
    cd tensorflow

    # Apply TensorFlow WIP patches here

    # https://github.com/tensorflow/tensorflow/pull/113368 - Bump Compute Library version from v24.12 to v52.8.0
    apply-github-patch tensorflow/tensorflow 189698cf3b3dab5375508ff2e02f6aba3a586323
)
