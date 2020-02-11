#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=mkl-dnn
readonly version=$DNNL_VERSION
readonly src_host=https://github.com/intel
readonly src_repo=mkl-dnn

# Clone tensorflow and benchmarks
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

export CMAKE_INSTALL_PREFIX=$PROD_DIR/$package/$version
export CMAKE_BUILD_TYPE=Release

# Apply path to allow use of newer Bazel build.
patch -p1 < ../dnnl.patch

mkdir -p build
cd build

blas_flag=""
[[ $DNNL_BUILD = "openblas" ]] && blas_flag="-DUSE_CBLAS -I$OPENBLAS_DIR/include"

CFLAGS=$blas_flag CXXFLAGS=$blas_flag \
  cmake -DCMAKE_INSTALL_PREFIX=$PROD_DIR/$package/$version  .. 

make -j $NP_MAKE
make install
