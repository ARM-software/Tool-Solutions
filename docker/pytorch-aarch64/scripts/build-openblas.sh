#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=openblas
readonly version=$OPENBLAS_VERSION
readonly src_host="https://github.com/xianyi"
readonly src_repo="OpenBLAS"

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

export CFLAGS="-O3"
export LDFLAGS="${BASE_LDFLAGS}"

install_dir=$PROD_DIR/$package/$version

make -j $NP_MAKE USE_OPENMP=1
make -j $NP_MAKE PREFIX=$install_dir install
