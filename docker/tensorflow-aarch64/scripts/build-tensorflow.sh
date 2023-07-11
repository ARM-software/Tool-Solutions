#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020-2023 Arm Limited and affiliates.
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
# Checkout Tensorflow unreleased 5c1dcfd
git checkout 5c1dcfd436548558312710ace3db60f56d2e082c

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
export TF_NEED_CLANG=0

./configure

# Bazel build options
config_flags=""
compile_flags="--copt=-mtune=${TUNE} --copt=-march=${ARCH} --copt=-O3 --copt=-flax-vector-conversions --copt=-Wno-error=stringop-overflow"
link_flags=""
extra_flags="--verbose_failures -s"

if [[ $BZL_RAM ]]; then extra_flags="$extra_flags --local_ram_resources=$BZL_RAM"; fi
if [[ $NP_MAKE ]]; then extra_flags="$extra_flags --jobs=$NP_MAKE"; fi

if [[ $ONEDNN_BUILD ]]; then
    echo "$ONEDNN_BUILD build for $TF_VERSION"
    if [[ $ONEDNN_BUILD == 'acl_threadpool' ]]; then
        config_flags="$config_flags --config=mkl_aarch64_threadpool"
    else
        config_flags="$config_flags --config=mkl_aarch64"
    fi
    if [[ $ONEDNN_BUILD == 'reference' ]]; then
        tf_backend_desc="oneDNN - reference."
        sed -i '/DNNL_AARCH64_USE_ACL/d' ./third_party/mkl_dnn/mkldnn_acl.BUILD
    else
        if [[ $ONEDNN_BUILD == 'acl_threadpool' ]]; then
            tf_backend_desc="oneDNN + Compute Library (threadpool runtime)."
        else
            tf_backend_desc="oneDNN + Compute Library (OpenMP runtime)."
        fi

        ### Apply patches to the TensorFlow, Compute Library and oneDNN builds
        ## TensorFlow patches:

        # Updates ACL to 23.05 and moves build to in-tree Bazel
        patch -p1 < ../tf_update_acl.patch
        # Moves some ops to Eigen for performance
        patch -p1 < ../tf_remedial_fixes.patch
        # Reduces MKL overhead for small shapes
        patch -p1 < ../tf_reduce_mkl_overheads_small_shapes.patch
        # Matmul heuristics
        patch -p1 < ../tf_matmul_heuristics.patch
        # Adds inter scheduler
        patch -p1 < ../tf_inter_scheduler.patch
        # Patch TensorFlow to update oneDNN and ACL builds
        patch -p1 < ../tf_acl.patch
        # Specify that format is any for weights for matmul and inner product
        patch -p1 < ../tf_mkl_matmul_defined_weights_as_any.patch

        ## oneDNN patches:
        # Patches to support JIT'ed reorder for padded inputs
        wget https://github.com/oneapi-src/oneDNN/commit/b84c533dad4db495a92fc6d390a7db5ebd938a88.patch -O ../onednn_acl_reorder_update.patch
        mv ../onednn_acl_reorder_update.patch ./third_party/mkl_dnn/.
        mv ../onednn_reorder_padded.patch ./third_party/mkl_dnn/.
        # Adds tensor dilation parameter configuration for Compute Library depthwise conv
        mv ../onednn_acl_depthwise_convolution_dilation.patch ./third_party/mkl_dnn/.
        # Remove Compute Library Winograd support
        mv ../onednn_acl_remove_winograd.patch ./third_party/mkl_dnn/.
        # Updates Depthwise patch in Tensorflow with changes for Compute Library 23.05
        mv ../onednn_acl_depthwise_convolution.patch ./third_party/mkl_dnn/.
        # Updates Fixed Format patch in Tensorflow with changes for Compute Library 23.05
        mv ../onednn_acl_fixed_format_kernels.patch ./third_party/mkl_dnn/.
        # Adds ACL reorder to oneDNN
        mv ../onednn_acl_reorder.patch ./third_party/mkl_dnn/.
        # Adds inter scheduler to oneDNN
        mv ../onednn_thread_local_scheduler.patch ./third_party/mkl_dnn/.
        # oneDNN ACL matmul fix
        mv ../onednn_acl_matmul.patch ./third_party/mkl_dnn/.

        ## Compute Library
        # Manually defining Compute Library version for now. Also removes FP16 support from Bazel build.
        mv ../compute_library.patch ./third_party/compute_library/.
        # Adds ACL reorder to ACL
        mv ../acl_acl_reorder.patch ./third_party/compute_library/.
        # Adds inter scheduler to ACL
        mv ../acl_thread_local_scheduler.patch ./third_party/compute_library/.

    fi
else
    tf_backend_desc="Eigen."
    config_flags="$config_flags --define tensorflow_mkldnn_contraction_kernel=0"

    # Manually set L1,2,3 caches sizes for the GEBP kernel in Eigen.
    [[ $EIGEN_L1_CACHE ]] && compile_flags="$compile_flags \
        --copt=-DEIGEN_DEFAULT_L1_CACHE_SIZE=${EIGEN_L1_CACHE}"
    [[ $EIGEN_L2_CACHE ]] && compile_flags="$compile_flags \
        --copt=-DEIGEN_DEFAULT_L2_CACHE_SIZE=${EIGEN_L2_CACHE}"
    [[ $EIGEN_L3_CACHE ]] && compile_flags="$compile_flags \
        --copt=-DEIGEN_DEFAULT_L3_CACHE_SIZE=${EIGEN_L3_CACHE}"
fi

echo "========================================================================"
echo " TensorFlow $TF_VERSION with backend: $tf_backend_desc"
echo "------------------------------------------------------------------------"
echo " build options:"
echo " - config_flags= $config_flags"
echo " - compile_flags= $compile_flags"
echo " - link_flags= $link_flags"
echo " - extra_flags= $extra_flags"
echo "========================================================================"

# Build the tensorflow configuration
bazel build $config_flags \
    $compile_flags \
    $link_flags \
    $extra_flags \
    //tensorflow/tools/pip_package:build_pip_package \
    //tensorflow:libtensorflow_cc.so \
    //tensorflow:install_headers

# Install Tensorflow python package via pip
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./wheel-TF$TF_VERSION-py$PY_VERSION-$CC
pip install $(ls -tr wheel-TF$TF_VERSION-py$PY_VERSION-$CC/*.whl | tail)

# Install Tensorflow C++ interface
mkdir -p $VIRTUAL_ENV/$package/lib
mkdir -p $VIRTUAL_ENV/$package/include
cp ./bazel-bin/tensorflow/libtensorflow* $VIRTUAL_ENV/$package/lib
cp -r ./bazel-bin/tensorflow/include $VIRTUAL_ENV/$package/
cp -r $VIRTUAL_ENV/lib/python$PY_VERSION/site-packages/tensorflow/include/google \
      $VIRTUAL_ENV/$package/include

# Move whl into venv for easy extraction from container
mkdir -p $VIRTUAL_ENV/$package/wheel
mv $(ls -tr wheel-TF$TF_VERSION-py$PY_VERSION-$CC/*.whl | tail) $VIRTUAL_ENV/$package/wheel

# Check the Python installation was sucessfull
cd $HOME
if python -c 'import tensorflow; print(tensorflow.__version__)' > version.log; then
    echo "TensorFlow $(cat version.log) package installed from $TF_VERSION branch."
else
    echo "TensorFlow Python package installation failed."
    exit 1
fi
rm $HOME/version.log
