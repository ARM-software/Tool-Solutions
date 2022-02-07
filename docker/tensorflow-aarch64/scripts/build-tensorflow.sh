#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020-2022 Arm Limited and affiliates.
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
git checkout $version

# Env vars used to avoid interactive elements of the build.
export HOST_C_COMPILER=(which gcc)
export HOST_CXX_COMPILER=(which g++)
export PYTHON_BIN_PATH=(which python)
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_ENABLE_XLA=1
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

if [[ $ONEDNN_BUILD ]]; then
    echo "$ONEDNN_BUILD build for $TF_VERSION"
    extra_args="$extra_args --config=mkl_aarch64 --linkopt=-fopenmp"
    if [[ $ONEDNN_BUILD == 'reference' ]]; then
      echo "TensorFlow $TF_VERSION with oneDNN backend - reference build."
      sed -i '/DNNL_AARCH64_USE_ACL/d' ./third_party/mkl_dnn/mkldnn_acl.BUILD
    elif [[ $ONEDNN_BUILD == 'acl' ]]; then
      echo "TensorFlow $TF_VERSION with oneDNN backend - Compute Library build."
      # Patch Compute Library Bazel build
      patch -p1 < ../tf_acl.patch
      # Patch to add experimental spin-wait scheduler to Compute Library
      # Note: overwrites upstream version
      mv ../compute_library.patch ./third_party/compute_library/.
    fi
else
    echo "TensorFlow $TF_VERSION with Eigen backend."
    extra_args="$extra_args --define tensorflow_mkldnn_contraction_kernel=0"

    # Manually set L1,2,3 caches sizes for the GEBP kernel in Eigen.
    [[ $EIGEN_L1_CACHE ]] && extra_args="$extra_args \
      --cxxopt=-DEIGEN_DEFAULT_L1_CACHE_SIZE=${EIGEN_L1_CACHE} \
      --copt=-DEIGEN_DEFAULT_L1_CACHE_SIZE=${EIGEN_L1_CACHE}"
    [[ $EIGEN_L2_CACHE ]] && extra_args="$extra_args \
      --cxxopt=-DEIGEN_DEFAULT_L2_CACHE_SIZE=${EIGEN_L2_CACHE} \
      --copt=-DEIGEN_DEFAULT_L2_CACHE_SIZE=${EIGEN_L2_CACHE}"
    [[ $EIGEN_L3_CACHE ]] && extra_args="$extra_args \
      --cxxopt=-DEIGEN_DEFAULT_L3_CACHE_SIZE=${EIGEN_L3_CACHE} \
      --copt=-DEIGEN_DEFAULT_L3_CACHE_SIZE=${EIGEN_L3_CACHE}"
fi

# Build the tensorflow configuration
bazel build $extra_args \
        --config=v2 --config=noaws \
        --copt="-mtune=${TUNE}" --copt="-march=${ARCH}" --copt="-O3"  --copt="-fopenmp" \
        --copt="-flax-vector-conversions" \
        --cxxopt="-mtune=${TUNE}" --cxxopt="-march=${ARCH}" --cxxopt="-O3"  --cxxopt="-fopenmp" \
        --cxxopt="-flax-vector-conversions" \
        --linkopt="-lgomp  -lm" \
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

# Move whl into venv for easy extraction from container
mkdir -p $VENV_DIR/$package/wheel
mv $(ls -tr wheel-TF$TF_VERSION-py$PY_VERSION-$CC/*.whl | tail) $VENV_DIR/$package/wheel

# Check the Python installation was sucessfull
cd $HOME
if python -c 'import tensorflow; print(tensorflow.__version__)' > version.log; then
    echo "TensorFlow $(cat version.log) package installed from $TF_VERSION branch."
else
    echo "TensorFlow Python package installation failed."
    exit 1
fi
rm $HOME/version.log
