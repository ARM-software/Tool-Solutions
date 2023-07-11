# TensorFlow for AArch64

**⚠ Please Note:**

These builds may contain features currently in active development (see the [change-log](./CHANGELOG.md) for more detail) and are intended only for evaluation purposes.
Testing of the full stack is limited to validation against the [examples](./examples/README.md) provided on a selection of AArch64 platforms, including Neoverse-V1, Neoverse-N1 and A72.
Release versions of TensorFlow are available from: https://pypi.org/project/tensorflow/.

## Contents
* [Getting started with TensorFlow on AArch64](#getting-started-with-tensorflow-on-aarch64)
   * [Downloading an image from Docker Hub](#downloading-an-image-from-docker-hub)
   * [Running the Docker image](#running-the-docker-image)
* [Image contents](#image-contents)
   * [Optimized backend for AArch64](#optimized-backend-for-aarch64)
      * [oneDNN runtime flags](#onednn-runtime-flags)
   * [Hardware support](#hardware-support)
   * [Examples](#examples)
* [Build TensorFlow (2.x) for AArch64 using Docker](#build-tensorflow-2x-for-aarch64-using-docker)
   * [Building a TensorFlow Serving image](#building-a-tensorflow-serving-image)
      * [Running a simple example with TensorFlow Serving](#running-a-simple-example-with-tensorflow-serving)

## Getting started with TensorFlow on AArch64
This [component](https://github.com/ARM-software/Tool-Solutions/tree/master/docker/tensorflow-aarch64) of [ARM-Software's](https://github.com/ARM-software) [Tool Solutions](https://github.com/ARM-software/Tool-Solutions) repository provides instructions to obtain, and scripts to build, a Docker image containing [TensorFlow](https://www.tensorflow.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile), optionally with AArch64 specific optimizations via [Compute Library for the Arm® Architecture (ACL)](https://developer.arm.com/ip-products/processors/machine-learning/compute-library), as well as a selection of [examples and benchmarks](./examples/README.md).

Ready-made Docker images including TensorFlow, dependencies, and examples, are available from [Arm SW Developers Docker Hub](https://hub.docker.com/u/armswdev), and are updated monthly, see [Downloading an image from Docker Hub](#downloading-an-image-from-docker-hub) for details.

Instructions for building TensorFlow for AArch64 from scratch in a Docker image, using the `build.sh` script provided in this repository, are available here: [Build TensorFlow (2.x) for AArch64 using Docker](#build-tensorflow-2x-for-aarch64-using-docker).

For more information, see this Arm Developer Community [blog post](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/aarch64-docker-images-for-pytorch-and-tensorflow).

The contents of [this folder](https://github.com/ARM-software/Tool-Solutions/tree/master/docker/tensorflow-aarch64) are updated on a monthly cadence. For more details on the significant changes with each increment, see the [changelog](./CHANGELOG.md).

### Downloading an image from Docker Hub

Completed images can be pulled from [armswdev/tensorflow-arm-neoverse](https://hub.docker.com/r/armswdev/tensorflow-arm-neoverse).

```
docker pull armswdev/tensorflow-arm-neoverse:<image tag>
```

Where `<image tag>` identifies the image version, as well as the TensorFlow version and backend:

`<image tag>` = `r<yy>.<mm>-tf-<TF version>-<backend>`

- `r<yy>.<mm>` = this identifies the monthly update to the images on Docker Hub; `yy` = year (e.g. 22 for 2022) and `mm` = month (e.g. 01 for January).
- `<TF version>` = TensorFlow version, see [image contents](#image-contents).
- `<backend>` = `eigen`, `onednn-acl`, or `onednn-acl_threadpool` see [optimized backend for AArch64](#optimized-backend-for-aarch64).

For example: `r23.05-tf-2.12.0-onednn-acl`.

### Running the Docker image
To run the downloaded image:

  ``` docker run -it --init <image name> ```

where `<image name> `is the name of the image, i.e. `armswdev/tensorflow-arm-neoverse:<image tag>`.

## Image contents

  * OS: Ubuntu 22.04
  * Compiler: GCC 11.3
  * Maths libraries: [OpenBLAS](https://www.openblas.net/) 0.3.20, used for NumPy's BLAS functionality
  * [oneDNN](https://github.com/oneapi-src/oneDNN) 2.7.3
    - ACL 23.05 provides optimized implementations on AArch64 for main oneDNN primitives
  * Python 3.10 environment containing:
    - NumPy 1.21.5
    - SciPy 1.7.3
    - TensorFlow unreleased, Git hash: 5c1dcfd
  * [Examples](./examples/README.md) that demonstrate how to run ML models
    - [MLCommons :tm:](https://mlcommons.org/en/) benchmarks with an optional patch to support benchmarking for TF oneDNN builds
    - TensorFlow Benchmarks
    - Python API examples
    - C++ API examples

The default user account has sudo privileges (username `ubuntu`, password `Portland`).

### Optimized backend for AArch64

Separate images are provided with Eigen and oneDNN backends (as given in the image tag). The scripts in this repository can be used to build either.

 * **Eigen:** this is the default backend for a TensorFlow build on AArch64, suitable for both training and inference workloads.
 * **oneDNN:** this uses oneDNN with ACL, providing optimized implementations on AArch64 for key oneDNN primitives. There is the option to use either an OpenMP build of oneDNN and ACL, or to use TensorFlow's Eigen threadpool throughout. Use the `--onednn acl` and `--onednn acl_threadpool` respectively to select between these options. The oneDNN backend is intended for inference workloads on infrastructure-scale platforms. oneDNN optimizations can be disabled at runtime by setting the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.

#### oneDNN runtime flags

- `ONEDNN_DEFAULT_FPMATH_MODE`: For builds where ACL is enabled, setting the environment variable `ONEDNN_DEFAULT_FPMATH_MODE` to `BF16` or `ANY` will instruct ACL to dispatch fp32 workloads to bfloat16 kernels where hardware support permits. _Note: this may introduce a drop in accuracy._
- `TF_ENABLE_ONEDNN_OPTS`: enables the oneDNN backend and is set to 1 (i.e. enabled) by default. To disable the oneDNN+ACL backend, set to `0`. _Note: this flag is only available for imaged built with the oneDNN+ACL backend._

### Hardware support

The images provided are intended for Arm Neoverse platforms. The oneDNN+ACL backend includes optimizations for Armv8.2-a and beyond to deliver improved performance on Neoverse targets, and support for hardware features such as SVE and bfloat16, where available.

They are compatible with all ARMv8-A targets. However, resource constraints may make them impractical for use on systems with low core counts and low memory. Server-scale platforms are recommended.

### Examples

A small selection of inference benchmarks and examples are provided with the image:

  * [MLCommons :tm:](https://mlcommons.org/en/) benchmarks
  * Python API examples
  * C++ API examples

More details can be found in the [examples](./examples/README.md) folder.

## Build TensorFlow (2.x) for AArch64 using Docker

Confirm the machine is AArch64, other architectures are not supported.

```
> uname -m
aarch64
```

Clone the Tool-Solutions repository, and go to the `docker/tensorflow-aarch64` directory:

```
git clone https://github.com/ARM-software/Tool-Solutions.git
cd Tool-Solutions/docker/tensorflow-aarch64
```

Use the `build.sh` script to build the image.

This script implements a multi-stage build to minimize the size of the final image:

  * Stage 1: 'base' image including Ubuntu with core packages and GCC
  * Stage 2: 'libs' image including essential tools and libraries such as Python and OpenBLAS
  * Stage 3: 'tools' image, including a Python3 virtual environment in userspace and a build of NumPy and SciPy against OpenBLAS, as well as other Python essentials
  * Stage 4: 'dev' image, including Bazel and TensorFlow and the source code
  * Stage 5: 'tensorflow' image, including only the Python3 virtual environment, the TensorFlow module, the basic benchmarks, and the example scripts. Bazel and TensorFlow sources are not included in this image

To see the command line options for `build.sh` use:

```
./build.sh -h
```

The image to build is selected with the `--build-type` flag. The options are base, libs, tools, dev, tensorflow, or full. Selecting full builds all of the images. The default value is 'tensorflow'.


For example:

  * To build the final tensorflow image:

    ```
    ./build.sh --build-type tensorflow
    ```

  * For a full build:

    ```
    ./build.sh --build-type full
    ```

  * For a base build:

    ```
    ./build.sh --build-type base
    ```

For the base build: This will generate an image named 'tensorflow-base-v2', hyphenated with the version of TensorFlow chosen.

TensorFlow can optionally be built with oneDNN, using the `--onednn` flag; in this case the oneDNN backend will be enabled by default, but can be disabled at runtime by setting the environment variable `TF_ENABLE_ONEDNN_OPTS=0`.
The backend for oneDNN can also be selected using the `--onednn` flag:
This defaults to using ACL, but `--onednn reference` can also be selected to use the reference C++ kernels.
Without the `--onednn` flag, the default Eigen backend of Tensorflow is chosen. For the final TensorFlow image with oneDNN: This will generate an image `tensorflow-v2$onednn` with the type of oneDNN backend chosen.


_Note: The oneDNN backend chosen will be appended to the image name: `tensorflow-v2$onednn`._

By default, all packages will be built with optimizations for the host machine, equivalent to setting `-mcpu=native` at compile time for each component build.
It is possible to choose a specific build target using the `--build-target` flag:

  * native       - optimize for the current host machine (default).
  * neoverse-n1  - optimize for Neoverse-N1.
  * neoverse-v1  - optimize for Neoverse-V1.
  * neoverse-n2  - optimize for Neoverse-N2.
  * neoverse     - generic optimization for all Neoverse cores.
  * thunderx2t99 - optimize for Marvell ThunderX2.
  * generic      - generate portable build suitable for any Armv8a target.
  * custom       - apply a custom set of architecture and tuning flags, as defined in [cpu_info.sh](cpu_info.sh).

Memory requirements for building TensorFlow can be significant, and may exceed the available
memory, particularly for parallel builds (the default). There are two flags which can be used to
control the resources Bazel consumes:

  * `--jobs` sets the number of jobs to run in parallel during the build, this will apply to all parallel builds
  * `--bazel_memory_limit` sets a memory limit for Bazel build, in MiB

In addition to the Dockerfile, please refer to the files in the `scripts/` and `patches/` directories to see how the software is built.
