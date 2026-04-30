#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2020-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

set -eux -o pipefail

# exec redirects all output from now on into a file and stdout
build_log=build-$(git rev-parse --short=7 HEAD)-$(date '+%Y-%m-%dT%H-%M-%S').log
exec &> >(tee -a "$build_log")

# Bail out if sources are already there
if [ -d pytorch ]; then
    printf "\n\n%s\n%s\n%s\n\n\n" \
        "You appear to have artefacts from a previous build lying around." \
        "Check for any of the following:" \
        "  - pytorch"

    if [[ "$*" != *--fresh* ]] && [[ "$*" != *--use-existing-sources* ]]; then
        >&2 printf "\n\n%s\n%s\n%s\n\n\n" \
            "Rerun with one of the following options:" \
            "  - '--fresh': wipe the pre-existing sources and do a fresh build" \
            "  - '--use-existing-sources': reuse the sources as is"
        exit 1
    fi

    # Wipe old build artefacts
    if [[ $* == *--fresh* ]]; then
        # Wipe the other directories; we should have the privileges now
        if [ -d pytorch ]; then rm -rf pytorch; fi
    fi
fi

# Older builds wrote this file for persistent builder-container reuse. The
# current flow uses Docker image layers and fresh containers instead.
rm -f .torch_build_container_id

if ! [[ $* == *--use-existing-sources* ]]; then
    ./get-source.sh
fi

# Set the output dir for the wheels
OUTPUT_DIR=${OUTPUT_DIR:-"${PWD}/results"}
export OUTPUT_DIR="${OUTPUT_DIR}"

# We build the wheel with ccache by default; allow disabling it via the --disable-ccache flag
build_wheel_args=()
if [[ "$*" == *--disable-ccache* ]]; then
    build_wheel_args+=(--disable-ccache)
fi
./build-wheel.sh "${build_wheel_args[@]}"

[[ $* == *--wheel-only* ]] && exit 0

# Use the second to last match, otherwise grep finds itself
torch_wheel_name=$(grep -o "torch-.*.whl" "$build_log" | head -n -1 | tail -n 1)

./dockerize.sh "results/${torch_wheel_name}" --build-only
