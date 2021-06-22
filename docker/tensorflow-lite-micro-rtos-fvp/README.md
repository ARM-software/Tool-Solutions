# Tensorflow Lite for Microcontrollers on Corstone 300 FVP (Cortex-M55 + Ethos-U55)

These instructions are available in the following languages
    
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" width="15" height="15" alt="English" style="vertical-align:middle" /> English](README.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" width="15" height="15" alt="Japanese" style="vertical-align:middle" /> 日本語](README-ja.md)

## Introduction

This repository contains instructions and scripts for setting up an environment for building and running applications for an Arm® Ethos™-U55 based platform.

Docker is used for setting up an environment that can be widely accessible, easy to deploy and reproducible. 

The environment comes with tools like the [Corstone 300 FVP](https://developer.arm.com/ip-products/subsystem/corstone/corstone-300) (Fixed Virtual Platform), and [Vela NN Optimizer](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela.git/about/). The FVP simulates an Arm® Cortex®-M and Arm® Ethos™-U55 (µNPU) platform. 

The repository includes a couple of example applications to get started with developing applications for a Cortex®-M and Ethos™-U platform.

## Table of Contents

- [Introduction](#introduction)
- [About the Demo Applications](#about-the-demo-applications)
    - [ethos-u repository](#ethos-u-repository)
    - [ml-embedded-evaluation-kit repository](#ml-embedded-evaluation-kit-repository)
- [Prerequisites](#prerequisites)
- [Dependencies](#dependencies)
- [Setup Environment](#setup-environment)
    - [Option 1: Using Docker (Recommended)](#option-1-using-docker-recommended)
    - [Option 2: Using native linux machine](#option-2-using-native-linux-machine)
        - [Install python](#install-python)
        - [Install new CMake](#install-new-cmake)
        - [Install ArmCompiler](#install-armcompiler)
        - [Install Arm GNU toolchain](#install-arm-gnu-toolchain)
- [Build demo applications](#build-demo-applications)
    - [Building ml-embedded-evaluation-kit applications](#building-ml-embedded-evaluation-kit-applications)
        - [Building and running demo applications](#building-and-running-demo-applications)
        - [Data injection demo](#data-injection-demo)
            - [Interpreting the results](#interpreting-the-results)
        - [Build manually](#build-manually)
        - [Add custom sample](#add-custom-sample)
    - [Ethos-U RTOS samples](#ethos-u-rtos-samples)
        - [Adding custom data to the RTOS-samples](#adding-custom-data-to-the-rtos-samples)
            - [Converting a model](#converting-a-model)
            - [Converting a folder with images](#converting-a-folder-with-images)
- [Modulate Memory speed with the Timing Adapter](#modulate-memory-speed-with-the-timing-adapter)
- [Vela Model Optimizer for Ethos-U](#vela-model-optimizer-for-ethos-u)
    - [Installing Vela](#installing-vela)
    - [Vela Configuration](#vela-configuration)

## About the Demo Applications
This project aims to support building applications using either the [ml-embedded-evaluation-kit repository](https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/) or the [ethos-u repository](https://git.mlplatform.org/ml/ethos-u/ethos-u.git/about/).

### ethos-u repository

This is the root repository for all Arm® Ethos™-U software. It is provided to help users download required repositories and place them in a tree structure.

It comes with a couple of basic demo applications running on the Corstone-300 (Cortex-M55 + Ethos-U55) platform. The demo applications has support for FreeRTOS, as well as bare-metal.

See more information about the repository at [https://git.mlplatform.org/ml/ethos-u/ethos-u.git/tree/README.md](https://git.mlplatform.org/ml/ethos-u/ethos-u.git/tree/README.md) and see more information about the Arm® Ethos™-U at [https://developer.arm.com/ip-products/processors/machine-learning/arm-ethos-u](https://developer.arm.com/ip-products/processors/machine-learning/arm-ethos-u)

In the [sw/ethos-u](sw/ethos-u) folder of this repository, there are a couple of additional samples, with FreeRTOS support, that can be built using the ethos-u repository as a base. 

### ml-embedded-evaluation-kit repository

This repository is for building and deploying Machine Learning (ML) applications targeted for Arm® Cortex®-M and Arm® Ethos™-U NPU.
To run evaluations using this software, we suggest using an [MPS3 board](https://developer.arm.com/tools-and-software/development-boards/fpga-prototyping-boards/mps3)
or a fixed virtual platform (FVP) that supports Ethos-U55 software fast model. Both environments run a combination of
the new [Arm® Cortex™-M55 processor](https://www.arm.com/products/silicon-ip-cpu/cortex-m/cortex-m55) and the
[Arm® Ethos™-U55 NPU](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u55).

The following sample applications are available in the ml-embedded-evaluation-kit:<br>
* ad (Anomaly Detection)
* asr (Automatic Speech Recognition)
* img_class (Imange Classification)
* inference_runner (Run any quantized tflite network)
* kws_asr (Keyword Spotting and Automatic Speech Recognition)
* kws (Keyword Spotting)

There is an additional person_detection sample in the [sw/ml-eval-kit](sw/ml-eval-kit) folder of this repository. 

## Prerequisites

The demo applications can be build with either the ArmCompiler (minimum version 6.14 required) or the GNU Arm Embedded Toolchain (minimum version 10.2.1 required).

- If you are using the proprietary Arm Compiler, ensure that the compiler license has been correctly configured.

When building the docker image the following packages will be downloaded to the root of this project:

* ArmCompiler 6.16 for Linux64: [DS500-BN-00026-r5p0-18rel0.tgz](https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-18rel0.tgz)
* GNU Arm Embedded Toolchain: [gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)
* Corstore-300 FVP with Arm® Ethos™-U55 support for Linux64: [FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz](https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/MPS3/FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz)

## Dependencies

This project has the following dependencies:

- [Docker](https://www.docker.com/)
- [Tensorflow](https://github.com/tensorflow/tensorflow/)
- [CMSIS](https://github.com/ARM-software/CMSIS_5/)
- [FreeRTOS](https://github.com/aws/amazon-freertos.git) + [Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel.git)
- [vela](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela)
- [ethos-u platform](https://review.mlplatform.org/ml/ethos-u/ethos-u)
- [ml-embedded-evaluation-kit](https://review.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit)
- [Corstone 300 FVP](https://developer.arm.com/ip-products/subsystem/corstone/corstone-300)



Models and Sample images used in this project are open source and the details can be found in the README.md of respective demo application.

## Setup Environment

The build scripts has been tested on CentOS7, Ubuntu 18.04 and 20.04, and Windows 10 PowerShell

### Option 1: Using Docker (Recommended)

0. Install Docker
    * Follow instructions here: https://docs.docker.com/get-docker/

1. Run the docker build script in a linux terminal or Windows Powershell:
    * Windows PowerShell:
        * If you wish to use the Arm Compiler
            ```commandline
            $ ./docker_build.PS1 -compiler armclang
            ```
        * If you wish to use the GNU GCC Compiler
            ```commandline
            $ ./docker_build.PS1 -compiler gcc
            ```
    * Linux:
        * If you wish to use the Arm Compiler
            ```commandline
            $ ./docker_build.sh -c armclang
            ```
        * If you wish to use the GNU GCC Compiler
            ```commandline
            $ ./docker_build.sh -c gcc
            ```

1. When the script has finished, you can find the image with this command
    ```commandline
    $ docker images | grep "tensorflow-lite-micro-rtos-fvp"
    REPOSITORY                       TAG              IMAGE ID       CREATED          SIZE
    tensorflow-lite-micro-rtos-fvp   <compiler>       2729c3d6f35b   2 minutes ago   <size>
    ```

    * There may be some images with `<None>` tags present after the build. These are cache images, used for speeding up the build process. These images can be removed with the followig command:
        ```commandline
        $ docker image prune -f
        ```

1. If you plan to use ArmCompiler, Make sure you have configured the Arm Compiler license and set the variables `$ARMLMD_LICENSE_FILE` and `$ARM_TOOL_VARIANT` accordingly

1. On linux, Make sure you have configured the `$DISPLAY` environment variable correctly. This is needed to be able to open the GUI of the applications.

1. Enter the docker image using the following command:
    * Windows:
        ```commandline
        $ docker run -it -e LOCAL_USER_ID=0 -e DISPLAY=<host-ip-address>:0.0 `
        -e ARMLMD_LICENSE_FILE=$env:ARMLMD_LICENSE_FILE `
        -e ARM_TOOL_VARIANT=$env:ARM_TOOL_VARIANT `
        --network host --privileged --rm tensorflow-lite-micro-rtos-fvp:<compiler> /bin/bash
        ```

        * You can modify this command if you want to use shared volumes to share the repository/build folder between the host and docker (e.g. `-v $PWD\dependencies:/work/dependencies:rw`). For some Windows users this don't work properly, so if you have any build issues, try again without sharing the dependencies folder as a first step. 
    * Linux:
        ```commandline
        $ ./docker_run.sh -i <compiler>
        ```

        * Other command line options:
            * -c : Send in a command to the docker container, such as 
                ```commandline
                $ ./docker_run.sh -i <compiler> -c ./linux_build_rtos_apps.sh
                ```
            * --share_folder : share a folder between the docker container and the host pc, for easy file copying (images etc) between them.
                ```commandline
                $ ./docker_run.sh -i <compiler> --share_folder share_folder
                ```

### Option 2: Using native linux machine

***This has been tested on Ubuntu 18.04, 20.04 and CentOS7***

#### Install python

We use python for some scripts. So you need to install some dependencies.

1. Install Python and TkInter

    ```commandline
    $ sudo apt install python3 python3-dev python3-venv python3-pip python3-tk
    ```


1. Verify that Python 3.6 or above is installed. Check your current installed version of Python by running:

    ```commandline
    $ python3 --version
    Python 3.6.8
    ```

1. Create a python virtual environment

    ```
    $ python3 -m venv .pyenv-tflm
    ```

1. Install packages to the virtual environment
    
    ```
    $ source ./.pyenv-tflm/bin/activate
    $ pip install --upgrade pip setuptools
    $ pip install -r requirements.txt
    ```

#### Install new CMake

For the builds to work, CMake version 3.15 or above is needed. The scripts in this repository has been verified to work with CMake versions 3.15-3.20.

Follow the installation instructions on the CMake website: 
`https://cmake.org/install/`

- After installing, test CMake by running:

    ```commandline
    $ cmake --version
    cmake version 3.16.2
    ```

> **Note:** How to add cmake to the path:
>
> `export PATH=/path/to/cmake/bin:$PATH`

#### Install ArmCompiler

If you are choosing to use ArmCompler over GCC, follow these instructions for installation.

1. Install ArmCompiler and the Corstore-300 FVP.

    1. After installing, add armclang and the Corstore-300 directories to your PATH environment variable.
        * Temporary 
            ```commandline
            $ export PATH=<armclang-install-dir>:$PATH
            $ export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
            ```
        * Persistent
            ```commandline
            $ echo "export PATH=<armclang-install-dir>:$PATH" >> ~/.bashrc
            $ echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
            $ source ~/.bashrc
            ```

    1. You need to set the `ARMLMD_LICENSE_FILE` environment variable to point at a running license server in order to run armclang, and `ARM_TOOL_VARIANT` needs to be set to the Arm Compiler license variant.

    1. Before proceeding, it is *essential* to ensure that the following prerequisites have been fulfilled:

        - ArmCompiler version 6.14 or higher:
        ```commandline
        $ armclang --version
        Product: ARM Compiler 6.16 Professional
        Component: ARM Compiler 6.16
        ```
        - Corstone-300 FVP version 11.12 or higher
        ```commandline
        $ FVP_Corstone_SSE-300_Ethos-U55 --version
        Fast Models [11.14.24 (Mar 23 2021)]
        Copyright 2000-2021 ARM Limited.
        All Rights Reserved.
        ```

    If you have any issues, make sure your PATH is configured correctly, and that you have the `ARMLMD_LICENSE_FILE` and `ARM_TOOL_VARIANT` configured correctly.

#### Install Arm GNU toolchain

If you choose to use GCC over ArmCompiler, follow these instructions to install.

1. Install [Arm GNU toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) by extracting to a folder on your system and the Corstore-300 FVP.

    1. After installing, add gcc and the Corstore-300 directories to your PATH environment variable.
        * Temporary 
            ```commandline
            $ export PATH=<gcc-install-dir>:$PATH
            $ export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
            ```
        * Persistent
            ```commandline
            $ echo "export PATH=<gcc-install-dir>:$PATH" >> ~/.bashrc
            $ echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
            $ source ~/.bashrc
            ```
    1. Check that PATH configured correctly

        ```commandline
        $ arm-none-eabi-gcc --version
        arm-none-eabi-gcc (GNU Arm Embedded Toolchain 10-2020-q4-major) 10.2.1 20201103 (release)
        ```
        ```commandline
        $ FVP_Corstone_SSE-300_Ethos-U55 --version
        Fast Models [11.14.24 (Mar 23 2021)]
        Copyright 2000-2021 ARM Limited.
        All Rights Reserved.
        ```

    If you have any issues, make sure your PATH is configured correctly.

## Build demo applications

### Building ml-embedded-evaluation-kit applications

This kit include baremetal sample applications for evaluating the Arm® Ethos™-U55 NPU.
The applications can run with either the FVP or directly on the MPS3 evaluation board.

There are two scripts that can be used for building the sample application. 

#### Building and running demo applications

The script `linux_build_eval_kit_apps.sh` will download and build the kit evaluation applications. Use this if you want to manually run the samples or if you want to bake your own sample images into the application for running on the FVP or on the MPS3 board. 
1. Build
    ```commandline
    $ ./linux_build_eval_kit_apps.sh
    ```
    * Use the command line option `--compiler` to select which compiler to build with (Not for docker).
    * Use the command line option `--use_case` to select which use case to build.
        * For example, if you want to evaluate the performance of a custom network, select `--use_case inference_runner` and provide the network as `--model <path/to/quantized/model.tflite>` (NOTE: No accuracy will be evaluated, only performance)
    * Use --help to see all command line options

1. Run sample
    1. On docker:
        ```commandline
        $ FVP_Corstone_SSE-300_Ethos-U55 -a dependencies/ml-embedded-evaluation-kit/build-docker/bin/<sample-name>.axf
        ```
    1. On native host:
        ```commandline
        $ FVP_Corstone_SSE-300_Ethos-U55 -a dependencies/ml-embedded-evaluation-kit/build/bin/<sample-name>.axf
        ```

    * The following windows will be opened. The Telnet terminal can be used for interaction with the application and shows evaluation results such as cycle count. The FVP main window, shows a virtual display, printing out the inference data and inference results.

    ![ethos-u-img_class.axf](res/FDv21.05-img_class.png)
    
    * To bake in your own data, copy your data (images/sound files) into the application sample folder and run the build script. 
        * Person Detection: `sw/ml-eval-kit/samples/resources/person_detection/samples/`
        * Other Samples: `dependencies/ml-embedded-evaluation-kit/resources/<use_case>/samples/`

    * If you have issues getting the X11 window to open, because of DISPLAY issues.
        You can use the Following command to run the demo without GUI:
        ```commandline
        $ FVP_Corstone_SSE-300_Ethos-U55 \
            -C mps3_board.visualisation.disable-visualisation=1 \
            -C mps3_board.uart0.out_file=- \
            -C mps3_board.telnetterminal0.start_telnet=0 \
            -C mps3_board.uart0.unbuffered_output=1 \
            -C mps3_board.uart0.shutdown_on_eot=1 \
            -C mps3_board.uart0.shutdown_tag="releasing platform" \
            -a dependencies/ml-embedded-evaluation-kit/build/bin/<sample-name>.axf
        ```

1. Interact with the sample
    Somtimes you need to interact with the sample applications.
    To do this, please open a second terminal and run
        ```commandline
        $ telnet localhost 5000
        ```

    * NOTE: When you are using docker, you need to enter the running docker container in the second terminal first:
        * Find the docker container-id of the running container
            ```commandline
            $ docker ps
            ```
        * Enter the docker container
            ```commandline
            $ docker exec -it <container-id> /bin/bash
            ```

#### Data injection demo
This is a demo doing data injection to an person_detection/img_class demo application. The application will have a single image built in, but this can be overwritten when starting the application. You can select a folder of images to use for the input, or you can choose to use a USB webcam. Each inference will take some time, since it is a simulation, so real time performance is not to be expected.

`data_injection_demo.py` will download, build and run the person_detection/img_class sample applications. Use this as a POC of how to inject data dynamically into the application.

* On docker:
    ```commandline
    $ source .pyenv-tflm/bin/activate
    $ ./data_injection_demo.py
    ```
* On native host:
    ```commandline
    $ source .pyenv-tflm/bin/activate
    $ ./data_injection_demo.py --compiler <armclang/gcc>
    ```
    * Images to inject into the application can be selected using the command line argument `--image_path=</full/path/to/image/or/folder>`
    * It is also possible use a USB camera to get the input data by using the option `--use_camera=True` (Each inference takes at least 10 seconds, so don't expect a smooth real time video)
    * Using `--speed_mode=True` will speed up the inference. This will invalidate the cycle count.
    * To perform inference on a video stream, the best way would be to convert the video frames into still images and use the frames as input
    
##### Interpreting the results

A window, like below, will open to show the (a)inference result, (b)memory read/write count and (c)NPU cycle count. 

![Python App Results](res/python-app-res.png)


#### Build manually

It is possible to manually build and run the ml-emedded-evaluation-kit by following the instructions for that project separately. The open source project is available here: `https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git`
The Docker container is fully compatible and all set up to work with these instructions.

#### Add custom sample

Add your own demo application by following the struction of the use case applications in the ml-emedded-evaluation-kit.

The person_detection demo, found in `sw/ml-eval-kit/samples/source/use_case/person_detection`, is derived from the img_class use case. By following the same kind of structure, it is fairly easy to develop a custom demo.

### Ethos-U RTOS samples
These applications are FreeRTOS sample applications and can run with either the FVP or directly on the MPS3 evaluation board.

1. Build
    ```commandline
    $ ./linux_build_rtos_apps.sh -c <compiler>
    ```

1. Run person_detection sample
    ```commandline
    $ ./run_demo_app.sh 
    ```

    * With the option `-a <path to application binary>`, you can choose to run another sample application. By default, the person_detection sample with run. You can find the built applications and libraries in `dependencies/ethos-u/build/bin/`, as well as in the subfolders of `dependencies/ethos-u/build/applications/`.


1. Interpret the results<br>
    Please see the documentation for each sample, to find how the inference output looks like:
    1. [Person Detection](sw/ethos-u/samples/person_detection/README.md#run-application-with-fvp)
    1. [Hello TFLM](sw/ethos-u/samples/hello_tflm/README.md#run-application-with-fvp)
    1. [Mobilenet V2](sw/ethos-u/samples/mobilenet_v2/README.md#run-application-with-fvp)


#### Adding custom data to the RTOS-samples

There are helper scripts available to convert tflite models and images to cp code.

They are located in:

* Docker: 
    `/usr/local/convert_scripts`
    
* Linux: 
    `scripts/convert_scripts`

##### Converting a model

Use the `convert_tflite_to_cpp.sh` script to convert a tflite model to cpp code.

```commandline
$ convert_tflite_to_cpp.sh --input <model.tflite> --output model_vela.cpp
```

After converting the model, you can add it to the project folder (e.g. `sw/ethos-u/samples/mobilenet_v2`), and recompile.  

##### Converting a folder with images

- For RGB images:
    ```commandline
    $ convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height>
    ```
- For Grayscale images:
    ```commandline
    $ convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height> \
        --grayscale 1
    ```

Add the resulting code files to the project folder (e.g. `sw/ethos-u/samples/mobilenet_v2`), and recompile. 


## Modulate Memory speed with the Timing Adapter

The Timing Adapter is a software library that can be used for evaluation purposes.
The Timing Adapter will sit between the memory and the device under test, Ethos-U55 in this case.

The Timing Adapter can modulate the memory speed, to simulate verious types of memory. This will enable benchmarking of a range of memory bandwidths and latencies on the same platform (FVP or FPGA).

The Ethos-U55 uses two AXI (one for SRAM and Flash each), which both can be configured to match the latencies and bandwith of the planned design.

* AXI0 is the SRAM, with the default configuration giving a read/write latancy of `32 cycles`, and a bandwidth of `4 GB/s`.
* AXI1 is the Flash, with the default configuration giving a read only latancy of `64 cycles`, and a bandwidth of `0.5 GB/s`.

The configuration file can be found here: `./dependencies\ml-embedded-evaluation-kit\scripts\cmake\ta_config.cmake`

Modify the `TAx_RLATENCY` and `TAx_WLATENCY` to change the latency of the memory connected to the AXI.
Modify the `TAx_PULSE_ON`, `TAx_PULSE_OFF` and `TAx_BWCAP` to change the bandwidth according to this formula (We call the result of these parameters for the Burst_Cycle here):
```
BW_multiplier = TAx_BWCAP / (TAx_PULSE_ON + TAx_PULSE_OFF)
BW = BW_multiplier * 4 GB/s
```

From the formula above, we see that in order to get `4 GB/s` (default SRAM), BW_multiplier should be `1`. And to get `0.5 GB/s` (default Flash), BW_multiplier should be `0.125`. 

If we want the bandwidth to be `0.25 GB/s`, we should choose values of the three variables so that BW_multiplier equals `0.0625`. To get this, we can choose these values: 
```
TAx_BWCAP=25
TAx_PULSE_ON=320
TAx_PULSE_OFF=80
```
BW_multiplier: 25 / (320 + 80) = 0.0625
BW: 4 GB/s * 0.0625 = 0.25 GB/s

The Timing Adapter documentation can be found here: [Timing Adapter Documentation](https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/tree/docs/sections/building.md#building-timing-adapter-with-custom-options) 

## Vela Model Optimizer for Ethos-U

Vela is installed in the docker image, making it possible to compile you own models.

Use vela like this:<br>
```commandline
$ vela <input_model.tflite>
```
The result is a compiled tflite model in the `output` folder.

### Installing Vela

Vela is available as a python package. Here are instructions on how to install. 

1. Prerequisites
    You will need to have python v3.6 or above. 
    We recommend using a virtualenv.

    Installing Python:
    ```commandline
    $ sudo apt update
    $ sudo apt install -y python3 python3-venv python3-dev python3-pip
    ```

1. Install Vela on the virtualenv

    ```commandline
    $ python3 -m venv .pyenv-tflm
    $ source ..pyenv-tflm/bin/activate
    $ python -m pip install ethos-u-vela
    ```

### Vela Configuration

You can configure Vela to take custom memory configurations in consideration when it is doing its performance estimation.
Configurable settings include memory latency and clock scale (which will affect the memory bandwidth).

An example of a vela configuration file can be found here:
`./dependencies\ml-embedded-evaluation-kit\scripts\vela\default_vela.ini`
You can modify this file, or create your own configuration file, where you configure the latency and memory bandwidth of your design.

In the vela configuration file, `Sram_clock_scale` and `OffChipFlash_clock_scale` is what modifies the bandwidth of the SRAM and Flash respectively. The clock_scale act as a multiplier to the bandwidth. So if you want half bandwidth (2 GB/s), set the clock_scale to `0.5`.

Another important command line argument of vela is to select the correct NPU and MAC configuration. This is done with the argument `--accelerator_config` and the value should be of the form ethos-u55-128. 

See more at [Vela Documentation](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela.git/about/) and [Vela command line example](https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/tree/docs/sections/building.md#optimize-custom-model-with-vela-compiler) 

