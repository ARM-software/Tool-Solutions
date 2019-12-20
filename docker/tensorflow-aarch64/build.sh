#!/usr/bin/env bash

# Staged docker build for TensorFlow
# ==================================

################################################################################
function print_usage_and_exit {
  echo "Usage: build.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help                   Display this message"
  echo "      --jobs                   Specify number of jobs to run in parallel during the build"
  echo "      --bazel_memory_limit     Set a memory limit for Bazel build"
  echo "      --build-type             Type of build to perform:"
  echo "                                 * base       - build the basic portion of the image, OS and essential packages"
  echo "                                 * libs       - build image including maths libraries and Python3."
  echo "                                 * tools      - build image including Python3 venv, with numpy."
  echo "                                 * dev        - build image including Bazel and TensorFlow, with sources."
  echo "                                 * tensorflow - build image including TensorFlow build and benchmarks installed"
  echo "                                 * full       - build all images."
  echo ""
  echo "Example:"
  echo "  build.sh --build-type full"
  exit $1
}

################################################################################

# Default build flags
build_base_image=
build_libs_image=
build_tools_image=
build_dev_image=
build_tensorflow_image=
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

    --jobs )
      nproc_build=$2
      shift
      ;;

    --bazel_memory_limit )
      bazel_mem=$2
      shift
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

if [[ $bazel_mem ]]; then
  # Set -j to use for builds, if specified
  extra_args="$extra_args --build-arg bazel_mem=$bazel_mem"
fi

echo $extra_args

if [[ $build_base_image ]]; then
  # Stage 1: Base image, Ubuntu with core packages and GCC9
  docker build $extra_args --target base -t base:latest .
fi

if [[ $build_libs_image ]]; then
  # Stage 2: Libs image, essential maths libs and Python built and installed
  docker build $extra_args --target libs -t libs:latest .
fi

if [[ $build_tools_image ]]; then
  # Stage 3: Tools image, Python3 venv added with additional Python essentials
  docker build $extra_args --target tools -t tools:latest .
fi

if [[ $build_dev_image ]]; then
  # Stage 4: Adds bazel and TensorFlow builds with sources
  docker build $extra_args --target dev -t dev:latest .
fi

if [[ $build_tensorflow_image ]]; then
  # Stage 5: Adds bazel and TensorFlow builds with sources
  docker build $extra_args --target tensorflow -t tensorflow:latest .
fi

