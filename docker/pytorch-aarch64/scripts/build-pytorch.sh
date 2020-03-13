#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=pytorch
readonly version=$TORCH_VERSION
readonly src_host=https://github.com/pytorch
readonly src_repo=pytorch
readonly num_cpus=$(grep -c ^processor /proc/cpuinfo)

# Clone pytorch
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version
git submodule sync
git submodule update --init --recursive

MAX_JOBS=${NP_MAKE:-$((num_cpus / 2))} OpenBLAS_HOME=$OPENBLAS_DIR/lib USE_LAPACK=1 USE_CUDA=0 USE_FBGEMM=0 USE_DISTRIBUTED=0 python setup.py install

# Check the installation was sucessfull
cd $HOME
python -c 'import torch; print(torch.__version__)' > version.log
if grep $version version.log; then
  echo "PyTorch $TORCH_VERSION package installed."
else
  echo "PyTorch package installation failed."
  exit 1
fi
rm $HOME/version.log
