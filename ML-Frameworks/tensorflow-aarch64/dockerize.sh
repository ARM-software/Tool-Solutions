#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

set -eux -o pipefail

help_str="dockerize.sh takes a TensorFlow wheel as argument. It \
installs the wheel inside a Docker container with examples and requirements."
if [ "$#" -lt 1 ]; then
    echo $help_str
    exit 1
fi

if ! [ -e "$1" ]; then
    echo "I couldn't find a wheel at $1"
    echo $help_str
    exit 1
fi

docker buildx \
    build --load \
    -t toolsolutions-tensorflow:latest  \
    --build-context rootdir=../.. \
    --build-arg TENSORFLOW_WHEEL=$1 \
    --build-arg DOCKER_IMAGE_MIRROR \
    .

[[ $* == *--build-only* ]] && exit 0
docker run --rm -it toolsolutions-tensorflow:latest
