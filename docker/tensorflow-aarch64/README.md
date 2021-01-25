# Build TensorFlow (1.x or 2.x) for AArch64 using Docker

A script to build a Docker image containing [TensorFlow](https://www.tensorflow.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile) with AArch64 execution.
For more information, see this Arm Developer Community [blog post](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/aarch64-docker-images-for-pytorch-and-tensorflow).

Before using this project run the uname command to confirm the machine is aarch64. Other architectures will not work.

```
> uname -m
aarch64
```


## What's in the final image?
  * OS: Ubuntu 18.04
  * Compiler: GCC 9.3.0
  * Maths libraries: [Arm Performance Libraries](https://developer.arm.com/tools-and-software/server-and-hpc/compile/arm-compiler-for-linux/arm-performance-libraries) 20.2.1 and [OpenBLAS](https://www.openblas.net/) 0.3.9
  * [oneDNN](https://github.com/oneapi-src/oneDNN) 0.21.3 or 1.7. Previously known as (MKL-DNN/DNNL).
  * Python3 environment built from CPython 3.7 and containing:
    - NumPy 1.17.1
    - TensorFlow 1.15.2 or TensorFlow 2.3.0
  * TensorFlow Benchmarks
  * [MLCommons (MLPerf)](https://mlperf.org/) benchmarks with an optional patch to support benchmarking for TF oneDNN builds.
**Note: Arm Performance Libraries provides optimized standard core math libraries for high-performance computing applications on Arm processors. This free version of the libraries provides optimized libraries for Arm Neoverse N1-based Armv8 AArch64 implementations that are compatible with various versions of GCC.

Use of the free of charge version of Arm Performance Libraries is subject to the terms and conditions of the applicable End User License Agreement (“EULA”).
A copy of the EULA can be found [here](https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-performance-libraries/eula)
The acompanying Third Party IP statement can be found [here](https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-performance-libraries/third-party-ip).**

A user account with username 'ubuntu' is created with sudo privileges and password of 'Arm2020'.

The TensorFlow Benchmarks repository are installed into the user home directory.

For example, to run the tf_cnn_benchmark for ResNet50:

``` > cd benchmarks/scripts/tf_cnn_benchmarks```

``` > python tf_cnn_benchmarks.py --device=CPU --batch_size=64 --model=resnet50 --variable_update=parameter_server --data_format=NHWC ```

In addition to the Dockerfile, please look at the files in the scripts/ directory and the patches/ directory to see how the software is built.


## Installing Docker
The [Docker Community Engine](https://docs.docker.com/install/) is used. Instructions on how to install Docker CE are available for various Linux distributions such as [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/) and [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

Confirm Docker is working:

``` > docker run hello-world ```

If there are any problems make sure the service is running:

``` > systemctl start docker ```

and make sure you are in the Docker group:

```  > usermod -aG docker $USER ```

These steps may require root privileges and usermod requires logout and login to take effect.

See https://docs.docker.com for more information.


## Building the Docker image
Use the build.sh script to build the image. This script implements a multi-stage build to minimise the size of the finished image:
  * Stage 1: 'base' image including Ubuntu with core packages and GCC9.
  * Stage 2: 'libs' image including essential tools and libraries such as Python, Arm Performance Libraries and OpenBLAS.
  * Stage 3: 'tools' image, including a Python3 virtual environment in userspace and a build of NumPy and SciPy against Arm Performance Libraries (or optionally OpenBLAS), as well as other Python essentials.
  * Stage 4: 'dev' image, including Bazel and TensorFlow and the source code
  * Stage 5: 'tensorflow' image, including only the Python3 virtual environment, the TensorFlow module, and the basic benchmarks. Bazel and TensorFlow sources are not included in this image.

To see the command line options for build.sh use:

``` > ./build.sh -h ```

The image to build is selected with the '--build-type' flag. The options are base, libs, tools, dev, tensorflow, or full. Selecting full builds all of the images. The default value is 'tensorflow'


For example:
  * To build the final tensorflow image:

    ``` > ./build.sh --build-type tensorflow ```

  * For a full build:

    ``` > ./build.sh --build-type full ```

  * For a base build:

    ```  > ./build.sh --build-type base ```

To choose between the different tensorflow versions use '--tf_version 1' for TensorFlow 1.15.2 or '--tf_version 2' for TensorFlow 2.3.0. The default value is set to tf_version=2.
For the base build: This will generate an image named 'DockerTest/ubuntu/base-v$tf_version', hyphenated with the version of TensorFlow chosen.

TensorFlow can optionally be built with oneDNN, using the '--onednn' or '--dnnl' flag. Tensorflow 1.x is built with oneDNN 0.21.3 (MKL-DNN) and Tensorflow 2.x is built with oneDNN 1.7.
Without the '--onednn' flag, the default Eigen backend of Tensorflow is chosen. For the final TensorFlow image with oneDNN: This will generate an image 'tensorflow-v$tf_version$onednn_blas with the type of onednn backend chosen.

The BLAS backend for oneDNN can also be selected using the '--onednn' or '--dnnl' flags:
For TensorFlow 1.x builds, this defaults to the C++ reference kernels, setting '--dnnl openblas' will use the OpenBLAS libary where possible.
For TensorFlow 2.x builds, this defaults to using Arm Performance Libraries, but '--onednn reference' and '--onednn openblas' can also be selected to use the reference C++ kernels, or OpenBLAS respectively.
_Note: The oneDNN backend chosen will be apended to the image name: `tensorflow-v$tf_version$onednn_blas`._
_Note: selecting OpenBLAS will also cause other dependencies (NumPy and SciPy) to be built against OpenBLAS rather than Arm Performance Libraries._

By default, all packages will built with optimisations for the host machine, equivalent to setting `-mcpu=native` at compile time for each component build.
It is possible to choose a specific build target using the `--build-target` flag:
  * native       - optimize for the current host machine (default).
  * neoverse-n1  - optimize for Neoverse-N1.
  * thunderx2t99 - optimize for Marvell ThunderX2.
  * generic      - generate portable build suitable for any Armv8a target.
_Note: The version of Arm Performance Libaries included will execute on any Armv8a target, but only includes optimisations for Neoverse-N1._


Memory requirements for building TensorFlow can be significant, and may exceed the available
memory, particularly for parallel builds (the default). There are two flags which can be used to
control the resources Bazel consumes:

  * --jobs sets the number of jobs to run in parallel during the build, this will apply to all parallel builds
  * --bazel_memory_limit sets a memory limit for Bazel build, in MiB

## Running the Docker image
To run the finished image:

  ``` > docker run -it --init <image name> ```

where <image name> is the name of the finished image, for example 'tensorflow-v2'.

  ``` > docker run -it --init tensorflow-v2 ```

To display available images use the Docker command:

  ``` > docker images ```

## Running MLCommons benchmark
Please refer to (https://github.com/mlperf/inference/tree/master/vision/classification_and_detection) to download datasets and models. Examples scripts are provided in the $HOME directory of the final image.

To run resnet50 on ImageNet min-validation dataset for image classification:

  ``` > export DATA_DIR=${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min ```

  ``` > export MODEL_DIR=$(pwd) ```

  ``` > ./run_local.sh tf resnet50 cpu ```

Use MKLDNN_VERBOSE=1 to verify the build uses oneDNN when running the benchmarks.

## Running MLCommons benchmark with the (optional) run_cnn.py wrapper script provided.

To find out the usages and default settings:

  ``` > ./run_cnn.py --help ```

To run benchmarks in the multiprogrammed mode:
  ``` > DATA_DIR=$abc MODEL_DIR=$def OMP_NUM_THREADS=$ghi ./run_cnn.py --processes $(nproc) --threads 1 ```

To run benchmarks in the multithreaded mode:

  ``` >  DATA_DIR=$abc MODEL_DIR=$def OMP_NUM_THREADS=$ghi ./run_cnn.py --processes 1 --threads $(nproc) ```

To run benchmarks in the hybrid mode:

For example, run 8 processes each of which has 8 threads on a 64-core machine

  ``` >  DATA_DIR=$abc MODEL_DIR=$def OMP_NUM_THREADS=$ghi ./run_cnn.py --processes 8 --threads 8 ```
