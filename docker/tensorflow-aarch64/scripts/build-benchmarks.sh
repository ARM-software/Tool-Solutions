#!/usr/bin/env bash
set -euo pipefail

cd /home/$DOCKER_USER
readonly package=benchmarks
readonly src_host=https://github.com/tensorflow
readonly src_repo=benchmarks

# Clone tensorflow and benchmarks

git clone ${src_host}/${src_repo}.git

