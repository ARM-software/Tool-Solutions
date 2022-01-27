#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2022 Arm Limited and affiliates.
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
readonly package=serving
readonly version=$TFSERVING_VERSION
readonly src_host=https://github.com/tensorflow
readonly src_repo=serving

# Clone TensorFlow Serving
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout $version

extra_args="--verbose_failures -s"
if [[ $BZL_RAM ]]; then extra_args="$extra_args --local_ram_resources=$BZL_RAM"; fi
if [[ $NP_MAKE ]]; then extra_args="$extra_args --jobs=$NP_MAKE"; fi

if [[ $ONEDNN_BUILD ]]; then
    echo "$ONEDNN_BUILD build for $TFSERVING_VERSION"
    extra_args="$extra_args --config=mkl_aarch64 --linkopt=-fopenmp"
    if [[ $ONEDNN_BUILD == 'reference' ]]; then
      echo "TensorFlow $TFSERVING_VERSION with oneDNN backend - reference build."
      sed -i '/DNNL_AARCH64_USE_ACL/d' ./third_party/mkl_dnn/mkldnn_acl.BUILD
    elif [[ $ONEDNN_BUILD == 'acl' ]]; then
      echo "TensorFlow $TFSERVING_VERSION with oneDNN backend - Compute Library build."
      # Patch Bazel configuration to include Arm Compute Library build
      wget https://github.com/tensorflow/serving/pull/1953.patch -O ../tfs_acl.patch
      patch -p1 < ../tfs_acl.patch
    fi
else
    echo "TensorFlow Serving $TFSERVING_VERSION with Eigen backend."
    extra_args="$extra_args --define tensorflow_mkldnn_contraction_kernel=0"
fi

# Build the tensorflow configuration
bazel build $extra_args \
        --copt="-mcpu=${CPU}" --copt="-march=${ARCH}" --copt="-O3"  --copt="-fopenmp" \
        --copt="-Wno-maybe-uninitialized" --copt="-Wno-stringop-truncation" --copt="-Wno-deprecated-declarations"\
        --cxxopt="-mcpu=${CPU}" --cxxopt="-march=${ARCH}" --cxxopt="-O3"  --cxxopt="-fopenmp" \
        --cxxopt="-Wno-maybe-uninitialized" --cxxopt="-Wno-stringop-truncation" --copt="-Wno-deprecated-declarations" \
        --linkopt="-lgomp  -lm" \
        tensorflow_serving/model_servers:tensorflow_model_server \
        tensorflow_serving/tools/pip_package:build_pip_package

cp ./bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server /home/$DOCKER_USER/tensorflow_model_server

# Install TensorFlow Serving python package via pip
./bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package $PWD/wheel-TFserving$TFSERVING_VERSION-py$PY_VERSION-$CC
pip --no-cache-dir install --no-dependencies $(ls -tr wheel-TFserving$TFSERVING_VERSION-py$PY_VERSION-$CC/tensorflow_serving_api-*.whl | tail)

# Check the installation was sucessfull
if /home/$DOCKER_USER/tensorflow_model_server --version > version.log; then
    cat version.log
    echo "installed from $TFSERVING_VERSION branch."
    bazel clean --expunge
else
    echo "TensorFlow Model Server installation failed."
    exit 1
fi
rm version.log
