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

# Staged docker build for TensorFlow
# ==================================

################################################################################

function print_usage_and_exit {
  echo "Usage: build.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help                   Display this message."
  echo "      --jobs                   Specify number of jobs to run in parallel during the build."
  echo "      --bazel_memory_limit     Set a memory limit for Bazel build."
  echo "      --onednn / --dnnl        Build and link to oneDNN / DNNL:"
  echo "                                 * reference      - use the C++ reference kernels throughout."
  echo "                                 * acl            - use Compute Library (default)."
  echo "                                 * acl_threadpool - use Compute Library with threadpool."
  echo "      --build-type             Type of build to perform:"
  echo "                                 * base           - build the basic portion of the image, OS and essential packages."
  echo "                                 * libs           - build image including maths libraries and Python3."
  echo "                                 * tools          - build image including Python3 venv, with numpy."
  echo "                                 * dev            - build image including Bazel and TensorFlow, with sources."
  echo "                                 * tensorflow     - build image including TensorFlow build and benchmarks installed (default)."
  echo "                                 * full           - build all images."
  echo "      --build-target           AArch64 CPU target:"
  echo "                                 * generic        - portable build suitable for any ARMv8-A target (default)."
  echo "                                 * native         - optimize for the current host machine."
  echo "                                 * neoverse-n1    - optimize for Neoverse-N1"
  echo "                                 * neoverse-v1    - optimize for Neoverse-V1"
  echo "                                 * neoverse-n2    - optimize for Neoverse-N2"
  echo "                                 * neoverse       - generic optimization for all Neoverse cores"
  echo "                                 * thunderx2t99   - optimize for Marvell ThunderX2."
  echo "                                 * custom         - use custom settings defined in cpu_info.sh"
  echo "                                 GCC provides support for additional target cpu's refer to the gcc manual for details."
  echo "      --no-cache / --clean     Pull a new base image and build without using any cached images."
  echo "      --tag                    Specify a tag name for the image (default 'latest')."
  echo ""
  echo "Example:"
  echo "  build.sh --build-type full"
  exit $1
}

################################################################################

# Import routines to set CPU properties.
source ./cpu_info.sh

# Enable Buildkit
# Required for advanced multi-stage builds
# Requires Docker v 18.09.1
export DOCKER_BUILDKIT=1

# Default build flags
build_base_image=
build_libs_image=
build_tools_image=
build_dev_image=
build_tensorflow_image=1
readonly target_arch="aarch64"
readonly host_arch=$(arch)

if ! [ "$host_arch" == "$target_arch" ]; then
   echo "Error: $(arch) is not supported"
   print_usage_and_exit 1
fi


# Default args
extra_args=""
nproc_build=
bazel_mem=
onednn=
enable_onednn=0
target="generic"
clean_build=
image_tag="latest"

while [ $# -gt 0 ]
do
  case $1 in
    --build-type )
      case $2 in
        base )
          build_base_image=1
          build_libs_image=
          build_tools_image=
          build_dev_image=
          build_tensorflow_image=
          ;;
        libs )
          build_base_image=
          build_libs_image=1
          build_tools_image=
          build_dev_image=
          build_tensorflow_image=
          ;;
        tools )
          build_base_image=
          build_libs_image=
          build_tools_image=1
          build_dev_image=
          build_tensorflow_image=
          ;;
        dev )
          build_base_image=
          build_libs_image=
          build_tools_image=
          build_dev_image=1
          build_tensorflow_image=
          ;;
        full )
          build_base_image=1
          build_libs_image=1
          build_tools_image=1
          build_dev_image=1
          build_tensorflow_image=1
          ;;
        tensorflow )
          build_base_image=
          build_libs_image=
          build_tools_image=
          build_dev_image=
          build_tensorflow_image=1
          ;;
        * )
          echo "Error: $2 is an invalid build type!"
          print_usage_and_exit 1
          ;;
      esac
      shift
      ;;

    --build-target )
      target=$2
      shift
      ;;

    --jobs )
      nproc_build=$2
      shift
      ;;

    --bazel_memory_limit )
      bazel_mem=$2
      shift
      ;;

    --onednn | --dnnl )
      enable_onednn=1
      if [[ $# -gt 1 ]]; then
        case $2 in
          reference )
            onednn="reference"
            shift
            ;;
          acl )
            onednn="acl"
            shift
            ;;
          acl_threadpool )
            onednn="acl_threadpool"
            shift
            ;;
          * )
            echo "Defaulting to oneDNN-ACL build."
            echo "Note: support for oneDNN builds with OpenBLAS or ArmPL is now deprecated."
            onednn="acl"
            ;;
        esac
      else
        onednn="acl"
      fi
      ;;

    --clean | --no-cache )
      clean_build=1
      ;;

    --tag )
      image_tag=$2
      shift
      ;;

    -h | --help )
      print_usage_and_exit 0
      ;;

  esac
  shift
done
exec > >(tee -i build-tfv2$onednn.log)
exec 2>&1

if [[ $nproc_build ]]; then
  # Set -j to use for builds, if specified
  extra_args="$extra_args --build-arg njobs=$nproc_build"
fi

if [[ $bazel_mem ]]; then
  # Set -j to use for builds, if specified
  extra_args="$extra_args --build-arg bazel_mem=$bazel_mem"
fi

# Add oneDNN build options
if [[ $onednn ]]; then
  extra_args="$extra_args --build-arg onednn_opt=$onednn --build-arg enable_onednn=$enable_onednn"
fi

if [[ $clean_build ]]; then
  # Pull a new base image, and don't use any caches
  extra_args="--pull --no-cache $extra_args"
fi

# Set TensorFlow version
tf_version="master-5c1dcfd"

# Add build-args to pass version numbers,
extra_args="$extra_args \
    --build-arg tf_version=$tf_version"

# Set CPU target props
set_target $target
extra_args="$extra_args --build-arg cpu=$cpu \
    --build-arg tune=$tune \
    --build-arg arch=$arch \
    --build-arg blas_cpu=$blas_cpu \
    --build-arg blas_ncores=$blas_ncores \
    --build-arg eigen_l1_cache=$eigen_l1_cache \
    --build-arg eigen_l2_cache=$eigen_l2_cache \
    --build-arg eigen_l3_cache=$eigen_l3_cache"

if [[ $build_base_image ]]; then
  # Stage 1: Base image, Ubuntu with core packages and GCC9
  docker build $extra_args --target tensorflow-base -t tensorflow-base-v2:$image_tag .
fi

if [[ $build_libs_image ]]; then
  # Stage 2: Libs image, essential maths libs and Python built and installed
  docker build $extra_args --target tensorflow-libs -t tensorflow-libs-v2:$image_tag .
fi

if [[ $build_tools_image ]]; then
  # Stage 3: Tools image, Python3 venv added with additional Python essentials
  docker build $extra_args --target tensorflow-tools -t tensorflow-tools-v2:$image_tag .
fi

if [[ $build_dev_image ]]; then
  # Stage 4: Adds bazel and TensorFlow builds with sources and creates a whl.
  docker build $extra_args --target tensorflow-dev -t tensorflow-dev-v2$onednn:$image_tag .
fi

if [[ $build_tensorflow_image ]]; then
  # Stage 5: Add examples and clone benchmarks with TensorFlow installed.
  docker build $extra_args --target tensorflow -t tensorflow-v2$onednn:$image_tag .
fi
