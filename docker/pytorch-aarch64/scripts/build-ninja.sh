#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=ninja
readonly version=$NINJA_VERSION
readonly src_host=https://github.com/ninja-build
readonly src_repo=ninja

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v${version} -b v${version}

export CFLAGS="${BASE_CFLAGS} -O3"
export LDFLAGS="${BASE_LDFLAGS}"
readonly confflags="" #"--enable-optimizations

install_dir=$PROD_DIR/$package/$version

./configure.py --bootstrap

mkdir -p $install_dir
cp ./ninja $install_dir/.
