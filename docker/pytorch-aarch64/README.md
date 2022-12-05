# PyTorch for AArch64

**⚠ Please Note:**

These builds may contain features currently in active development (see the [change-log](./CHANGELOG.md) for more detail) and are intended only for evaluation purposes.
Testing of the full stack is limited to validation against the [examples](./examples/README.md) provided on a selection of AArch64 platforms, including Neoverse-V1 and Neoverse-N1.
Release versions of PyTorch are available from: https://pypi.org/project/torch/.

## Contents
* [Getting started with PyTorch on AArch64](#getting-started-with-pytorch-on-aarch64)
   * [Downloading an image from Docker Hub](#downloading-an-image-from-docker-hub)
   * [Running the Docker image](#running-the-docker-image)
* [Image contents](#image-contents)
   * [Optimized backend for AArch64](#optimized-backend-for-aarch64)
      * [oneDNN runtime flags](#onednn-runtime-flags)
   * [Hardware support](#hardware-support)
   * [Examples](#examples)
* [Build PyTorch for AArch64 using Docker](#build-pytorch-for-aarch64-using-docker)

## Getting started with PyTorch on AArch64

This [component](https://github.com/ARM-software/Tool-Solutions/tree/master/docker/pytorch-aarch64) of [ARM-Software's](https://github.com/ARM-software) [Tool Solutions](https://github.com/ARM-software/Tool-Solutions) repository provides instructions to obtain, and scripts to build, a Docker image containing [PyTorch](https://www.pytorch.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile), optionally with AArch64 specific optimizations via [Compute Library for the Arm® Architecture (ACL)](https://developer.arm.com/ip-products/processors/machine-learning/compute-library), as well as a selection of [examples and benchmarks](./examples/README.md).

Ready-made Docker images including Pytorch, dependencies, and examples, are available from [Arm SW Developers Docker Hub](https://hub.docker.com/u/armswdev), and are updated monthly, see [Downloading an image from Docker Hub](#downloading-an-image-from-docker-hub) for details.

Instructions for building PyTorch for AArch64 from scratch in a Docker image, using the `build.sh` script provided in this repository, are available here: [Build PyTorch for AArch64 using Docker](#build-pytorch-for-aarch64-using-docker).

For more information, see this Arm Developer Community [blog post](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/aarch64-docker-images-for-pytorch-and-tensorflow).

The contents of [this folder](https://github.com/ARM-software/Tool-Solutions/tree/master/docker/pytorch-aarch64) are updated on a monthly cadence. For more details on the significant changes with each increment, see the [changelog](./CHANGELOG.md).

### Downloading an image from Docker Hub

Completed images can be pulled from [armswdev/pytorch-arm-neoverse](https://hub.docker.com/r/armswdev/pytorch-arm-neoverse).

```
docker pull armswdev/pytorch-arm-neoverse:<image tag>
```

Where `<image tag>` identifies the image version, as well as the PyTorch version and backend:

`<image tag>` = `r<yy>.<mm>-torch-<torch version>-<backend>`

- `r<yy>.<mm>` = this identifies the monthly update to the images on Docker Hub; `yy` = year (e.g. 22 for 2022) and `mm` = month (e.g. 01 for January).
- `<torch version>` = PyTorch version, see [image contents](#image-contents).
- `<backend>` = `openblas` or `onednn-acl`, see [optimized backend for AArch64](#optimized-backend-for-aarch64).

For example: `r22.06-torch-1.11.0-onednn-acl`.

### Running the Docker image
To run the downloaded image:

  ``` docker run -it --init <image name> ```

where `<image name>` is the name of the image, i.e. `armswdev/pytorch-arm-neoverse:<image tag>`.


## Image contents

  * OS: Ubuntu 20.04
  * Compiler: GCC 10.3
  * Maths libraries: [OpenBLAS](https://www.openblas.net/) 0.3.20
  * [oneDNN](https://github.com/oneapi-src/oneDNN) 2.7
    - ACL 22.11, provides optimized implementations on AArch64 for main oneDNN primitives
  * Python 3.8.10 environment containing:
    - NumPy 1.21.5
    - SciPy 1.7.3
    - PyTorch 1.13.0
  * [Examples](./examples/README.md) that demonstrate how to run ML models
    - [MLCommons :tm:](https://mlcommons.org/en/) benchmarks
    - Python API examples
    - C++ API examples

The default user account has sudo privileges (username `ubuntu`, password `Portland`).


### Optimized backend for AArch64

Separate images are provided with OpenBLAS and oneDNN backends (as given in the image tag). The scripts in this repository can be used to build either.

 * **OpenBLAS:** this is the default fp32 backend for a PyTorch build on AArch64, suitable for both training and inference workloads.
 * **oneDNN:** this uses oneDNN with ACL, providing optimized implementations on AArch64 for key oneDNN primitives. It is intended for inference workloads on infrastructure-scale platforms.

#### oneDNN runtime flags

- `DNNL_DEFAULT_FPMATH_MODE`: For builds where ACL is enabled, setting the environment variable `DNNL_DEFAULT_FPMATH_MODE` to `BF16` or `ANY` will instruct ACL to dispatch fp32 workloads to bfloat16 kernels where hardware support permits. _Note: this may introduce a drop in accuracy._

### Hardware support

The images provided are intended for Arm Neoverse platforms. The oneDNN+ACL backend includes optimizations for Armv8.2-a and beyond for Neoverse targets, and support for hardware features such as SVE and bfloat16, where available.

### Examples

A small selection of inference benchmarks and examples are provided with the image:

  * [MLCommons :tm:](https://mlcommons.org/en/) benchmarks
  * Python API examples
  * C++ API examples

More details can be found in the [examples](./examples/README.md) folder.

# Build PyTorch for AArch64 using Docker

Confirm the machine is AArch64, other architectures are not supported.

```
> uname -m
aarch64
```

Clone the Tool-Solutions repository, and go to the `docker/pytorch-aarch64` directory:

```
git clone https://github.com/ARM-software/Tool-Solutions.git
cd Tool-Solutions/docker/pytorch-aarch64
```

Use the `build.sh` script to build the image.

This script implements a multi-stage build to minimize the size of the final image:

  * Stage 1: 'base' image including Ubuntu with core packages and GCC
  * Stage 2: 'libs' image including essential tools and libraries such as Python and OpenBLAS
  * Stage 3: 'tools' image, including a Python3 virtual environment in userspace and a build of NumPy against OpenBLAS, as well as other Python essentials
  * Stage 4: 'dev' image, including PyTorch with sources
  * Stage 5: 'pytorch' image, including only the Python3 virtual environment, the PyTorch module, and the example scripts. PyTorch sources are not included in this image

To see the command line options for `build.sh` use:

```
./build.sh -h
```

The image to build is selected with the `--build-type` flag. The options are base, libs, tools, dev, pytorch, or full. Selecting full builds all of the images. The default value is 'pytorch'


For example:

  * To build the final pytorch image:

    ```
    ./build.sh --build-type pytorch
    ```

  * For a full build:

    ```
    ./build.sh --build-type full
    ```

  * For a base build:

    ```
    ./build.sh --build-type base
    ```

    This will generate an image named `pytorch-base`.

PyTorch can optionally be built with oneDNN, using the `--onednn` flag. By default this will use AArch64 optimized primitives from ACL where available. Specifying `--onednn reference` will disable ACL primitives and use oneDNN's reference C++ kernels throughout.

For builds where ACL is enabled, setting the environment variable `ONEDNN_DEFAULT_FPMATH_MODE` to `BF16` or `ANY` will instruct ACL to dispatch fp32 workloads to bfloat16 kernels where hardware support permits. Note: this may introduce a drop in accuracy.

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

In addition to the Dockerfile, please refer to the files in the `scripts/` and `patches/` directories to see how the software is built.
