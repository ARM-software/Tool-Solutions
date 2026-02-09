#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

set -eux -o pipefail

help_str="dockerize.sh takes a PyTorch wheel as the first argument and an ao wheel
as the second argument. It installs the wheel inside a Docker container with examples
and requirements. The docker image will then be run unless you pass in the optional
--build-only argument"

if [ "$#" -lt 2 ]; then
    echo $help_str
    exit 1
fi

if ! [ -e "$1" ] || ! [ -e "$2" ]; then
    echo "I couldn't find wheels at $1 and $2"
    echo $help_str
    exit 1
fi

IMAGE_USERNAME="${USERNAME:-$(. /etc/os-release && echo "$ID")}"
echo "USERNAME=$IMAGE_USERNAME"

docker buildx \
    build --load \
    -t toolsolutions-pytorch:latest  \
    --build-context rootdir=../.. \
    --build-arg DOCKER_IMAGE_MIRROR \
    --build-arg TORCH_WHEEL=$1 \
    --build-arg TORCH_AO_WHEEL=$2 \
    --build-arg USERNAME="$IMAGE_USERNAME" \
    .

[[ $* == *--build-only* ]] && exit 0
docker run --rm -it toolsolutions-pytorch:latest
