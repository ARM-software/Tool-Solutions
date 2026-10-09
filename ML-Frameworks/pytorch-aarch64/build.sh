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
    printf "\n\n%s\n\n\n" \
        "You appear to have the 'pytorch/' folder lying around from a previous build."

    if [[ "$*" != *--fresh* ]] && [[ "$*" != *--use-existing-sources* ]]; then
        printf "\n\n%s\n%s\n%s\n\n\n" \
            "Rerun with one of the following options:" \
            "  - '--fresh': wipe the pre-existing sources and do a fresh build" \
            "  - '--use-existing-sources': reuse the sources as is" >&2
        exit 1
    fi

    if [[ $* == *--fresh* ]]; then
        if [ -d pytorch ]; then rm -rf pytorch; fi
    fi
fi

# Older builds wrote this file for persistent builder-container reuse. The
# current flow uses Docker image layers and fresh containers instead.
rm -f .torch_build_container_id

if ! [[ $* == *--use-existing-sources* ]]; then
    get_source_args=()
    args=("$@")
    for ((i = 0; i < ${#args[@]}; i++)); do
        case "${args[$i]}" in
            --source-variant)
                if [[ $((i + 1)) -ge ${#args[@]} ]]; then
                    echo "error: --source-variant requires a value" >&2
                    exit 1
                fi
                get_source_args+=(--source-variant "${args[$((i + 1))]}")
                i=$((i + 1))
                ;;
            --source-variant=*)
                get_source_args+=("${args[$i]}")
                ;;
        esac
    done

    ./get-source.sh "${get_source_args[@]}"
fi

# Set the output dir for the wheels
OUTPUT_DIR=${OUTPUT_DIR:-"${PWD}/results"}
export OUTPUT_DIR="${OUTPUT_DIR}"

# We build the wheel with ccache by default; allow disabling it via the --disable-ccache flag
build_wheel_args=()
if [[ "$*" == *--disable-ccache* ]]; then
    build_wheel_args+=(--disable-ccache)
fi
wheel_path_file=$(mktemp)
trap 'rm -f "$wheel_path_file"' EXIT
PYTORCH_WHEEL_PATH_FILE="$wheel_path_file" ./build-wheel.sh "${build_wheel_args[@]}"

[[ $* == *--wheel-only* ]] && exit 0

# Use the repaired artifact reported by the wheel builder, not its raw-wheel log.
if ! IFS= read -r torch_wheel_path < "$wheel_path_file" || [[ ! -f "$torch_wheel_path" ]]; then
    echo "error: wheel builder did not report an existing repaired wheel" >&2
    exit 1
fi

./dockerize.sh "$torch_wheel_path" --build-only
