#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=python
readonly version=$PY_VERSION
readonly src_host=https://github.com/python
readonly src_repo=cpython

git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

export CFLAGS="${BASE_CFLAGS} -O3"
export LDFLAGS="${BASE_LDFLAGS} -lpthread"
readonly confflags="" #"--enable-optimizations

install_dir=$PROD_DIR/$package/$version
mkdir Build
cd Build

../configure $confflags # --prefix=$install_dir
make -j $NP_MAKE
make install

update-alternatives --install /usr/bin/python python /usr/local/bin/python3 1
update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip3 1

