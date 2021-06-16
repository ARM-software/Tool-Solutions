#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020-2021 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************

set -euo pipefail

cd $PACKAGE_DIR
readonly package=tensorflow
readonly version=$TF_VERSION
readonly src_host=https://github.com/tensorflow
readonly src_repo=tensorflow

# Clone tensorflow and benchmarks
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version -b $version

# Apply path to allow use of newer Bazel build.
if [[ $ONEDNN_BUILD ]]; then
        # TF2.3.0 fix: https://github.com/tensorflow/tensorflow/pull/41232#issuecomment-670049428
        patch -p1 < ../oneDNN-opensource.patch
        patch -p1 < ../tf2_onednn_decoupling.patch
        patch -p1 < ../tf2-onednn-explicit.patch
        if [[ $ONEDNN_BUILD == 'acl' ]]; then
            echo 'Patching for TensorFlow oneDNN - ACL'
            patch -p1 < ../tf2-acl.patch
        else
            echo 'TensorFlow oneDNN-reference'
        fi
    fi
patch -p1 < ../tensorflow2.patch

# Env vars used to avoid interactive elements of the build.
export HOST_C_COMPILER=(which gcc)
export HOST_CXX_COMPILER=(which g++)
export PYTHON_BIN_PATH=(which python)
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_ENABLE_XLA=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_MPI=0
export TF_NEED_ROCM=0
export TF_NEED_GCP=0
export TF_NEED_S3=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_CUDA=0
export TF_NEED_HDFS=0
export TF_NEED_OPENCL=0
export TF_NEED_JEMALLOC=1
export TF_NEED_VERBS=0
export TF_NEED_AWS=0
export TF_NEED_GDR=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_COMPUTECPP=0
export TF_NEED_KAFKA=0
export TF_NEED_TENSORRT=0

./configure

extra_args="--verbose_failures -s"
if [[ $BZL_RAM ]]; then extra_args="$extra_args --local_ram_resources=$BZL_RAM"; fi
if [[ $NP_MAKE ]]; then extra_args="$extra_args --jobs=$NP_MAKE"; fi
if [[ $ONEDNN_BUILD == 'acl' ]]; then extra_args="$extra_args --cxxopt=-DDNNL_AARCH64_USE_ACL=1"; fi

if [[ $ONEDNN_BUILD ]]; then
    echo "$ONEDNN_BUILD build for $TF_VERSION"
    extra_args="$extra_args --config=mkl_opensource_only --linkopt=-fopenmp"

else
    echo "Eigen-only build for $TF_VERSION"
    extra_args="$extra_args --define tensorflow_mkldnn_contraction_kernel=0"
fi

# Build the tensorflow configuration
bazel build $extra_args \
        --config=v2 --config=noaws \
        --copt="-mcpu=${CPU}" --copt="-O3" --copt="-flax-vector-conversions" --copt="-moutline-atomics" \
        --cxxopt="-mcpu=${CPU}" --cxxopt="-O3" --cxxopt="-flax-vector-conversions" --cxxopt="-moutline-atomics" \
        //tensorflow/tools/pip_package:build_pip_package \
        //tensorflow:libtensorflow_cc.so \
        //tensorflow:install_headers

# Install Tensorflow python package via pip
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./wheel-TF$TF_VERSION-py$PY_VERSION-$CC
pip install $(ls -tr wheel-TF$TF_VERSION-py$PY_VERSION-$CC/*.whl | tail)

# Install Tensorflow C++ interface
mkdir -p $VENV_DIR/$package/lib
mkdir -p $VENV_DIR/$package/include
cp ./bazel-bin/tensorflow/libtensorflow* $VENV_DIR/$package/lib
cp -r ./bazel-bin/tensorflow/include $VENV_DIR/$package/
cp -r $VENV_DIR/lib/python$PY_VERSION/site-packages/tensorflow/include/google \
      $VENV_DIR/$package/include

# Check the Python installation was sucessfull
cd $HOME
if python -c 'import tensorflow; print(tensorflow.__version__)' > version.log; then
    echo "TensorFlow $(cat version.log) package installed from $TF_VERSION branch."
else
    echo "TensorFlow Python package installation failed."
    exit 1
fi
rm $HOME/version.log
