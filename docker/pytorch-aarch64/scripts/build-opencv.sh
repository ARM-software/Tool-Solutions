#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=opencv 
readonly src_host=https://github.com/opencv
readonly src_repo=opencv
readonly num_cpus=$(grep -c ^processor /proc/cpuinfo)

git clone ${src_host}/${src_repo}.git 

cd $PACKAGE_DIR/$package
mkdir -p build
cd build
export CFLAGS="${BASE_CFLAGS} -O3"
export LDFLAGS="${BASE_LDFLAGS}"

py_inc=/usr/local/include/python${PY_VERSION:0:3}m

py_bin=$VENV_DIR/bin/python
py_site_packages=$VENV_DIR/lib64/python${PY_VERSION:0:3}/site-packages/
install_dir=$VENV_DIR/$package

cmake -DPYTHON3_EXECUTABLE=$py_bin -DPYTHON3_INCLUDE_DIR=$py_inc -DPYTHON3_PACKAGES_PATH=$py_site_packages \
  -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=$install_dir ..

make -j ${NP_MAKE:-$((num_cpus / 2))}
make install


