#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2020 Arm Limited and affiliates.
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
readonly tf_id=$TF_VERSION_ID
readonly src_host=https://github.com/tensorflow
readonly src_repo=tensorflow

# Clone tensorflow and benchmarks
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

# Checking out mkl_matmul_op.cc from master branch as it has API and code changes for oneDNN 1.x compared with Tensorflow 2.2.0.
if [[ $tf_id == '2' ]]; then
	git checkout master -- tensorflow/core/kernels/mkl_matmul_op.cc
fi

# Apply path to allow use of newer Bazel build.
if [[ $tf_id == '1' ]]; then
   if [[ $ONEDNN_BUILD ]]; then
       patch -p1 < ../tf_dnnl_decoupling.patch
   fi
   patch -p1 < ../tensorflow.patch
elif [[ $tf_id == '2' ]]; then
   if [[ $ONEDNN_BUILD ]]; then
   	patch -p1 < ../tf2_onednn_decoupling.patch
   	patch -p1 <../oneDNN-header.patch
   fi
   patch -p1 < ../tensorflow2.patch
else
   echo 'Invalid TensorFlow version when applying patches to the TensorFlow repository'
   exit 1
fi

# Env vars used to avoid interactive elements of the build.
export HOST_C_COMPILER=(which gcc)
export HOST_CXX_COMPILER=(which g++)
export PYTHON_BIN_PATH=(which python)
export USE_DEFAULT_PYTHON_LIB_PATH=1
export CC_OPT_FLAGS=""
export TF_ENABLE_XLA=0
export TF_NEED_GCP=0
export TF_NEED_S3=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_CUDA=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MPI=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_ROCM=0

./configure

extra_args=""
if [[ $BZL_RAM ]]; then extra_args="$extra_args --local_ram_resources=$BZL_RAM"; fi
if [[ $NP_MAKE ]]; then extra_args="$extra_args --jobs=$NP_MAKE"; fi

if [[ $ONEDNN_BUILD ]]; then
   echo "$ONEDNN_BUILD build for $TF_VERSION"
   if [[ $tf_id == '1' ]]; then
       bazel build $extra_args \
        --define=build_with_mkl_dnn_only=true --define=build_with_mkl=true \
        --define=tensorflow_mkldnn_contraction_kernel=1 \
        --copt="-mtune=native" --copt="-march=armv8-a" --copt="-O3" --copt="-fopenmp" \
        --cxxopt="-mtune=native" --cxxopt="-march=armv8-a" --cxxopt="-O3" --cxxopt="-fopenmp" \
        --linkopt="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" --linkopt="-fopenmp" \
        --config=noaws --config=v$tf_id  --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
        //tensorflow/tools/pip_package:build_pip_package
   elif [[ $tf_id == '2' ]]; then
       bazel build $extra_args \
        --define=build_with_mkl_dnn_v1_only=true --define=build_with_mkl=true \
        --define=tensorflow_mkldnn_contraction_kernel=1 \
        --copt="-mtune=native" --copt="-march=armv8-a" --copt="-O3" --copt="-fopenmp" \
        --cxxopt="-mtune=native" --cxxopt="-march=armv8-a" --cxxopt="-O3" --cxxopt="-fopenmp" \
        --linkopt="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" --linkopt="-fopenmp" \
        --config=noaws --config=v$tf_id  --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
        //tensorflow/tools/pip_package:build_pip_package
   else
       echo 'Invalid TensorFlow version when building tensorflow'
       exit 1
   fi
else
    echo "Eigen-only build for $TF_VERSION"
    bazel build $extra_args --define tensorflow_mkldnn_contraction_kernel=0 \
     --copt="-mtune=native" --copt="-march=armv8-a" --copt="-O3" \
     --cxxopt="-mtune=native" --cxxopt="-march=armv8-a" --cxxopt="-O3" \
     --copt="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" \
     --config=noaws --config=v$tf_id --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
     //tensorflow/tools/pip_package:build_pip_package
fi
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./wheel-TF$TF_VERSION-py$PY_VERSION-$CC

pip install $(ls -tr wheel-TF$TF_VERSION-py$PY_VERSION-$CC/*.whl | tail)

# Check the installation was sucessfull
cd $HOME
python -c 'import tensorflow; print(tensorflow.__version__)' > version.log

if grep -qx $version version.log; then
  echo "TensorFlow $TF_VERSION package installed."
  # Clean up Bazel cache
else
  echo "TensorFlow package installation failed."
  exit 1
fi

rm $HOME/version.log 
