#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=dnnl
readonly version=$DNNL_VERSION
readonly src_host=https://github.com/intel
readonly src_repo=mkl-dnn

# Clone tensorflow and benchmarks
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

export CMAKE_INSTALL_PREFIX=$PROD_DIR/$package/$version
export CMAKE_BUILD_TYPE=Release

# Apply patch to add AArch64 flags, and OpenBLAS lib
# This patch is for version 0.20.6
patch -p1 < ../mkldnn.patch

# This patch should be used for version 1.1.2 
#patch -p1 < ../dnnl.patch

mkdir -p build
cd build

blas_flag=""
[[ $DNNL_BUILD = "openblas" ]] && blas_flag="-DUSE_CBLAS -I$OPENBLAS_DIR/include"

CFLAGS="$BASE_CFLAGS $blas_flag" CXXFLAGS="$BASE_CFLAGS $blas_flag" \
  cmake -DCMAKE_INSTALL_PREFIX=$PROD_DIR/$package/$version  .. 

make -j $NP_MAKE
make install
