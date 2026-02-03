#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2019-2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

set -eux -o pipefail

# exec redirects all output from now on into a file and stdout
build_log=build-$(git rev-parse --short=7 HEAD)-$(date '+%Y-%m-%dT%H-%M-%S').log
exec &> >(tee -a $build_log)

# # Bail out if sources are already there
if [ -d tensorflow ] ; then
    printf "\n\n%s\n%s\n%s\n\n\n" \
        "You appear to have artefacts from a previous build lying around." \
        "Check for the following:" \
        "  - tensorflow"

    if ! ([[ $* == *--fresh* ]] || [[ $* == *--use-existing-sources* ]]) ; then
        printf "\n\n%s\n%s\n%s\n\n\n" \
                "Rerun with one of the following options:" \
                "  - '--fresh': wipe the pre-existing sources and do a fresh build" \
                "  - '--use-existing-sources': reuse the sources as is" 1>&2
        exit 1
    fi

    # Wipe old build artefacts
    if [[ $* == *--fresh* ]]; then
        if [ -d tensorflow ]; then
            # Change permissions for folders created as root in docker
            if [ -d tensorflow/build_output ]; then
                if [ ! -z "$(docker ps -a --no-trunc | grep tf)" ]; then
                    docker exec tf chown -R $(id -u):$(id -g) build_output 2>/dev/null || true
                else
                    printf "\n\n%s\n%s\n%s\n\n\n" \
                        "Unable to locate docker container 'tf'. You may need to" \
                        "rerun this script with sudo privileges to make sure everything" \
                        "has been properly wiped."
                fi
            fi

            # Wipe the container. Adapted from: tensorflow/ci/official/utilities/cleanup_docker.sh
            docker rm -f tf 2>/dev/null || true

            # Wipe the folder
            rm -rf tensorflow
        fi
    fi
fi

if ! [[ $* == *--use-existing-sources* ]]; then
    ./get-source.sh
fi

./build-wheel.sh

# Use the second to last match, otherwise grep finds itself
tf_wheel_name=$(grep -o "tensorflow-.*.whl" $build_log | head -n -1 | tail -n 1)
echo $tf_wheel_name

./dockerize.sh "results/$tf_wheel_name" --build-only
