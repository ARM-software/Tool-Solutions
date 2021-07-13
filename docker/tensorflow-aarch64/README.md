# Build TensorFlow (2.x) for AArch64 using Docker

A script to build a Docker image containing [TensorFlow](https://www.tensorflow.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile) with AArch64 execution.
For more information, see this Arm Developer Community [blog post](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/aarch64-docker-images-for-pytorch-and-tensorflow).

Before using this project run the uname command to confirm the machine is aarch64. Other architectures will not work.

```
uname -m
aarch64
```

Pre-built images are available for download from [Arm's Software Developers DockerHub](https://hub.docker.com/r/armswdev/tensorflow-arm-neoverse-n1).

## What's in the final image?
  * OS: Ubuntu 20.04
  * Compiler: GCC 9.3.0
  * Maths libraries: [OpenBLAS](https://www.openblas.net/) 0.3.10, [Arm Compute Library](https://developer.arm.com/ip-products/processors/machine-learning/compute-library) 21.05.
  * [oneDNN](https://github.com/oneapi-src/oneDNN) 2.2. Previously known as (MKL-DNN/DNNL).
  * Python3 environment containing:
    - NumPy 1.19.5
    - TensorFlow 2.5.0. (_Note: support for TensorFlow 1.x is now deprecated. Please use the [tensorflow-v1-aarch64)](https://github.com/ARM-software/Tool-Solutions/releases/tag/tensorflow-v1-aarch64) tag_).
    - SciPy 1.5.2
  * TensorFlow Benchmarks
  * [MLCommons :tm: (MLPerf)](https://mlperf.org/) benchmarks with an optional patch to support benchmarking for TF oneDNN builds.
  * [Example scripts](./examples/README.md) that demonstrate how to run ML models.


A user account with username 'ubuntu' is created with sudo privileges and password of 'Portland'.

The TensorFlow Benchmarks repository are installed into the user home directory.

For example, to run the `tf_cnn_benchmark` for ResNet50:

```
cd examples/benchmarks/scripts/tf_cnn_benchmarks
python tf_cnn_benchmarks.py --device=CPU --batch_size=64 --model=resnet50 --variable_update=parameter_server --data_format=NHWC
```

In addition to the Dockerfile, please refer to the files in the `scripts/` and `patches/` directories to see how the software is built.

## Installing Docker
The [Docker Community Engine](https://docs.docker.com/install/) is used. Instructions on how to install Docker CE are available for various Linux distributions such as [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/) and [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

Confirm Docker is working:

``` docker run hello-world ```

If there are any problems make sure the service is running:

``` systemctl start docker ```

and make sure you are in the Docker group:

```  usermod -aG docker $USER ```

These steps may require root privileges and usermod requires logout and login to take effect.

See https://docs.docker.com for more information.


## Building the Docker image
Use the build.sh script to build the image. This script implements a multi-stage build to minimise the size of the finished image:
  * Stage 1: 'base' image including Ubuntu with core packages and GCC9.
  * Stage 2: 'libs' image including essential tools and libraries such as Python and OpenBLAS.
  * Stage 3: 'tools' image, including a Python3 virtual environment in userspace and a build of NumPy and SciPy against OpenBLAS, as well as other Python essentials.
  * Stage 4: 'dev' image, including Bazel and TensorFlow and the source code
  * Stage 5: 'tensorflow' image, including only the Python3 virtual environment, the TensorFlow module,the basic benchmarks and the example scripts. Bazel and TensorFlow sources are not included in this image.

To see the command line options for build.sh use:

``` ./build.sh -h ```

The image to build is selected with the '--build-type' flag. The options are base, libs, tools, dev, tensorflow, or full. Selecting full builds all of the images. The default value is 'tensorflow'


For example:

  * To build the final tensorflow image:

    ``` ./build.sh --build-type tensorflow ```

  * For a full build:

    ``` ./build.sh --build-type full ```

  * For a base build:

    ```  ./build.sh --build-type base ```

For the base build: This will generate an image named 'DockerTest/ubuntu/base-v2', hyphenated with the version of TensorFlow chosen.

TensorFlow can optionally be built with oneDNN, using the '--onednn' or '--dnnl' flag. Tensorflow 2.x is built with oneDNN 2.2.
Without the '--onednn' flag, the default Eigen backend of Tensorflow is chosen. For the final TensorFlow image with oneDNN: This will generate an image 'tensorflow-v2$onednn with the type of onednn backend chosen.

The backend for oneDNN can also be selected using the '--onednn' or '--dnnl' flags:
This defaults to using Compute Library for Arm Architecture, but '--onednn reference' can also be selected to use the reference C++ kernels.
_Note: The oneDNN backend chosen will be apended to the image name: `tensorflow-v2$onednn`._

By default, all packages will built with optimisations for the host machine, equivalent to setting `-mcpu=native` at compile time for each component build.
It is possible to choose a specific build target using the `--build-target` flag:
  * native       - optimize for the current host machine (default).
  * neoverse-n1  - optimize for Neoverse-N1.
  * thunderx2t99 - optimize for Marvell ThunderX2.
  * generic      - generate portable build suitable for any Armv8a target.
  * custom       - apply a custom set of architecture and tuning flags, as defined in [cpu_info.sh](cpu_info.sh).

Memory requirements for building TensorFlow can be significant, and may exceed the available
memory, particularly for parallel builds (the default). There are two flags which can be used to
control the resources Bazel consumes:

  * --jobs sets the number of jobs to run in parallel during the build, this will apply to all parallel builds
  * --bazel_memory_limit sets a memory limit for Bazel build, in MiB

## Running the Docker image
To run the finished image:

  ``` docker run -it --init <image name> ```

where <image name> is the name of the finished image, for example 'tensorflow-v2'.

  ``` docker run -it --init tensorflow-v2 ```

To display available images use the Docker command:

  ``` docker images ```
