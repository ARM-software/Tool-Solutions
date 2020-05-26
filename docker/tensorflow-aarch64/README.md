# Build TensorFlow for AArch64 using Docker

A script to build a Docker image containing [TensorFlow](https://www.tensorflow.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile) with AArch64 execution. 

Before using this project run the uname command to confirm the machine is aarch64. Other architectures will not work.

``` 
> uname -m 
aarch64 
```


## What's in the final image?
  * OS: Ubuntu 18.04
  * Compiler: GCC 9.2
  * Maths libraries: [Arm Optimized Routines](https://github.com/ARM-software/optimized-routines) and [OpenBLAS](https://www.openblas.net/) 0.3.7
  * Python3 environment built from CPython 3.7 and containing:
    - NumPy 1.17.1
    - TensorFlow 1.15
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

Note: these scripts enable Docker BuildKit by default. This requires Docker verison 18.09.1 or newer and can be dissabled by removing `export DOCKER_BUILDKIT=1` from `build.sh`.


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

    This will generate an image named 'DockerTest/ubuntu/base'. 

Tensorflow can optionally be built with DNNL, using the '--dnnl' flag, either useing the C++ reference kernels throughout,
'--dnnl reference', or with the addition of OpenBLAS for BLAS calls '--dnnl openblas'

Memory requirements for building TensorFlow can be singificant, and may exceed the available
memory, paricuarly for parallel builds (the default). There are two flags which can be used to 
control the resources Bazel consumes:

  * --jobs sets the number of jobs to run in parallel during the build, this will apply to all parallel builds/
  * --bazel_memory_limit sets a memory limit for Bazel build, in MiB

## Running the Docker image
To run the finished image:

  ``` > docker run -it --init <image name> ```

where <image name> is the name of the finished image, for example 'tensorflow'.

  ``` > docker run -it --init tensorflow ```

To display available images use the Docker command:

  ``` > docker images ```


