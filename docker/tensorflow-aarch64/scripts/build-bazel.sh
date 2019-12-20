#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=bazel
readonly version=$BZL_VERSION

mkdir -p $package
cd $package

wget https://github.com/bazelbuild/bazel/releases/download/$version/bazel-$version-dist.zip
unzip bazel-$version-dist.zip

#EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" 
bash ./compile.sh
