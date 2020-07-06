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
  * Compiler: GCC 9.2
  * Maths libraries: [Arm Optimized Routines](https://github.com/ARM-software/optimized-routines) and [OpenBLAS](https://www.openblas.net/) 0.3.9
  * [oneDNN](https://github.com/oneapi-src/oneDNN) 0.21.3 or 1.4. Previously known as (MKL-DNN/DNNL).
  * Python3 environment built from CPython 3.7 and containing:
    - NumPy 1.17.1
    - TensorFlow 1.15.2 or TensorFlow 2.2.0
  * TensorFlow Benchmarks

A user account with username 'ubuntu' is created with sudo privaleges and password of 'Arm2020'.

The TensorFlow Benchmarks repository are installed into the user home directory.

For example, to run the tf_cnn_benchmark for ResNet50:

``` > cd benchmarks/scripts/tf_cnn_benchmarks```

``` > python tf_cnn_benchmarks.py --device=CPU --batch_size=64 --model=resnet50 --variable_update=parameter_server --data_format=NHWC ```

In addition to the Dockerfile, please look at the files in the scripts/ directory and the patches/ directory too see how the software is built.


## Installing Docker
The [Docker Community Engine](https://docs.docker.com/install/) is used. Instructions on how to install Docker CE are available for various Linux distributions such as [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/) and [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

Confirm Docker is working:

``` > docker run hello-world ```

If there are any problems make sure the service is running:

``` > systemctl start docker ```

and make sure you are in the Docker group:

```  > usermod -aG docker $USER ```

These steps may require root privlages and usermod requires logout and login to take effect.

See https://docs.docker.com for more information.


## Building the Docker image
Use the build.sh script to build the image. This script implements a multi-stage build to minimise the size of the finished image:
  * Stage 1: 'base' image including Ubuntu with core packages and GCC9.
  * Stage 2: 'libs' image including essential tools and libraries such as Python and OpenBLAS.
  * Stage 3: 'tools' image, including a Python3 virtual environment in userspace and a build of NumPy against OpenBLAS, as well as other Python essentials.
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

  * To choose between the different tensorflow versions use '--tf_version 1' for TensorFlow 1.15.2 or '--tf_version 2' for TensorFlow 2.2.0. The default value is set to tf_version=1.
    For the base build: This will generate an image named 'DockerTest/ubuntu/base-v$tf_version', hyphenated with the version of TensorFlow chosen.

TensorFlow can optionally be built with oneDNN, using the '--onednn' or '--dnnl' flag, either using the C++ reference kernels throughout,
'--onednn reference', or with the addition of OpenBLAS for BLAS calls '--onednn openblas'. Tensorflow 1.x is built with oneDNN 0.21.3 (MKL-DNN) and Tensorflow 2.x is built with oneDNN 1.4.
Without the '--onednn' flag, the default Eigen backend of Tensorflow is chosen. For the final TensorFlow image with oneDNN: This will generate an image 'tensorflow-v$tf_version$onednn_blas with the type of onednn backend chosen.

Memory requirements for building TensorFlow can be singificant, and may exceed the available
memory, particularly for parallel builds (the default). There are two flags which can be used to
control the resources Bazel consumes:

  * --jobs sets the number of jobs to run in parallel during the build, this will apply to all parallel builds/
  * --bazel_memory_limit sets a memory limit for Bazel build, in MiB

## Running the Docker image
To run the finished image:

  ``` > docker run -it --init <image name> ```

where <image name> is the name of the finished image, for example 'tensorflow-v2'.

  ``` > docker run -it --init tensorflow-v2 ```

To display available images use the Docker command:

  ``` > docker images ```


