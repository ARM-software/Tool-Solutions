#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2025 Arm Limited and affiliates.
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
    cd tensorflow
    git-bump nightly
)

echo "Put this into your get-source.sh file"
echo TENSORFLOW_HASH=$(cd tensorflow && git rev-parse HEAD)
