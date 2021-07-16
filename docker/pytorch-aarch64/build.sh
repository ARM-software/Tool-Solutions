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

# Staged docker build for PyTorch
# ==================================

################################################################################
function print_usage_and_exit {
  echo "Usage: build.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help                   Display this message"
  echo "      --jobs                   Specify number of jobs to run in parallel during the build"
  echo "      --onednn / --dnnl        Build and link to oneDNN / DNNL:"
  echo "                                 * reference    - use the C++ reference kernels throughout."
  echo "                                 * acl          - use Compute Library (default)."
  echo "      --build-type             Type of build to perform:"
  echo "                                 * base       - build the basic portion of the image, OS and essential packages"
  echo "                                 * libs       - build image including maths libraries and Python3."
  echo "                                 * tools      - build image including Python3 venv, with numpy."
  echo "                                 * dev        - build image including Bazel and PyTorch, with sources."
  echo "                                 * pytorch    - build image including PyTorch build and benchmarks installed"
  echo "                                 * full       - build all images."
  echo "      --build-target           AArch64 CPU target:"
  echo "                                 * native       - optimize for the current host machine (default)."
  echo "                                 * neoverse-n1  - optimize for Neoverse-N1"
  echo "                                 * thunderx2t99 - optimize for Marvell ThunderX2."
  echo "                                 * generic      - generate portable build suitable for any Armv8a target."
  echo "                                 * custom       - use custom settings defined in cpu_info.sh"
  echo "                                 GCC provides support for additional target cpu's refer to the gcc manual for details."
  echo "      --no-cache / --clean     Pull a new base image and build without using any cached images."
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
build_pytorch_image=1

readonly target_arch="aarch64"
readonly host_arch=$(arch)

if ! [ "$host_arch" == "$target_arch" ]; then
   echo "Error: $(arch) is not supported"
   print_usage_and_exit 1
fi


# Default args
extra_args=""
nproc_build=
onednn=
target="native"
clean_build=

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
          build_pytorch_image=
          ;;
        libs )
          build_base_image=
          build_libs_image=1
          build_tools_image=
          build_dev_image=
          build_pytorch_image=
          ;;
         tools )
          build_base_image=
          build_libs_image=
          build_tools_image=1
          build_dev_image=
          build_pytorch_image=
          ;;
        dev )
          build_base_image=
          build_libs_image=
          build_tools_image=
          build_dev_image=1
          build_pytorch_image=
          ;;
        full )
          build_base_image=1
          build_libs_image=1
          build_tools_image=1
          build_dev_image=1
          build_pytorch_image=1
          ;;
        pytorch )
          build_base_image=
          build_libs_image=
          build_tools_image=
          build_dev_image=
          build_pytorch_image=1
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

    --onednn | --dnnl )
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

    -h | --help )
      print_usage_and_exit 0
      ;;

  esac
  shift
done

exec > >(tee -i build.log)
exec 2>&1

if [[ $nproc_build ]]; then
  # Set -j to use for builds, if specified
  extra_args="$extra_args --build-arg njobs=$nproc_build"
fi

if [[ $clean_build ]]; then
  # Pull a new base image, and don't use any caches
  extra_args="--pull --no-cache $extra_args"
fi

if [[ $onednn ]]; then
  # Use oneDNN backend
  extra_args="--build-arg onednn_opt=$onednn $extra_args"
fi

# Set CPU target props
set_target $target
extra_args="$extra_args --build-arg cpu=$cpu \
    --build-arg tune=$tune \
    --build-arg arch=$arch \
    --build-arg blas_cpu=$blas_cpu \
    --build-arg acl_arch=$acl_arch"

if [[ $build_base_image ]]; then
  # Stage 1: Base image, Ubuntu with core packages and GCC9
  docker build $extra_args --target pytorch-base -t pytorch-base:latest .
fi

if [[ $build_libs_image ]]; then
  # Stage 2: Libs image, essential maths libs and Python built and installed
  docker build $extra_args --target pytorch-libs -t pytorch-libs:latest .
fi

if [[ $build_tools_image ]]; then
  # Stage 3: Tools image, Python3 venv added with additional Python essentials
  docker build $extra_args --target pytorch-tools -t pytorch-tools:latest .
fi

if [[ $build_dev_image ]]; then
  # Stage 4: Adds PyTorch build with sources
  docker build $extra_args --target pytorch-dev -t pytorch-dev${onednn:+"-$onednn"}:latest .
fi

if [[ $build_pytorch_image ]]; then
  # Stage 5: Adds PyTorch examples
  docker build $extra_args --target pytorch -t pytorch${onednn:+"-$onednn"}:latest .
fi

