#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

source ../utils/git-utils.sh

set -eux -o pipefail

TENSORFLOW_HASH=b5d8801b1e0db562ced3f7f940c65f25d7aea453 # from nightly, Sep 24th

git-shallow-clone https://github.com/tensorflow/tensorflow.git $TENSORFLOW_HASH
