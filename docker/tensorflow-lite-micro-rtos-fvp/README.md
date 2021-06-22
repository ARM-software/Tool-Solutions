# Tensorflow Lite for Microcontrollers on Corstone 300 FVP (Cortex-M55 + Ethos-U55)

These instructions are available in the following languages
    
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" width="15" height="15" alt="English" style="vertical-align:middle" /> English](README.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" width="15" height="15" alt="Japanese" style="vertical-align:middle" /> 日本語](README-ja.md)

## Preface

This repository contains instructions and scripts for setting up an environment for building and running applications for [Arm Ethos-U55 Micro NPU(µNPU)](https://www.arm.com/ja/products/silicon-ip-cpu/ethos/ethos-u55).

The environment comes with tools like the [Corstone 300 FVP](https://developer.arm.com/ip-products/subsystem/corstone/corstone-300) (Fixed Virtual Platform), and [Vela NN Optimizer](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela.git/about/) The FVP simulates an Arm Cortex-M and Arm Ethos-U55 (µNPU) platform. 

Corstone-300 FVP can be downloaded free of charge. Docker can be used for setting up an environment that can be widely accessible, easy to deploy and reproducible. 

The repository contains several samples for TensorFlow Lite for Microcontroller (TFLM) -based machine learning inference and neural network model optimizer [Ethos-U Vela Optimizer](https://pypi.org/project/ethos-u-vela/) to get started developing and running applications for the platform based on [Arm Cortex-M55](https://www.arm.com/ja/products/silicon-ip-cpu/cortex-m/cortex-m55) and [Arm Ethos-U55](https://www.arm.com/ja/products/silicon-ip-cpu/ethos/ethos-u55). 

Follow the instructions below to get started! 

---
## Index

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Tensorflow Lite for Microcontrollers on Corstone 300 FVP (Cortex-M55 + Ethos-U55)](#tensorflow-lite-for-microcontrollers-on-corstone-300-fvp-cortex-m55-ethos-u55)
  - [Preface](#preface)
  - [Index](#index)
  - [Introduction](#introduction)
  - [Preparation](#preparation)
    - [Contents and dependencies](#contents-and-dependencies)
  - [Setting up environment](#setting-up-environment)
    - [Option 1: Using Docker(Recommended)](#option-1-using-dockerrecommended)
    - [Option 2: Using Linux console](#option-2-using-linux-console)
      - [Setting up Linux environment](#setting-up-linux-environment)
      - [Install Arm Compiler](#install-arm-compiler)
      - [Install Arm GNU toolchain](#install-arm-gnu-toolchain)
  - [About the Demo Applications](#about-the-demo-applications)
    - [ethos-u repository](#ethos-u-repository)
    - [ml-embedded-evaluation-kit repository](#ml-embedded-evaluation-kit-repository)
  - [Building Applications](#building-applications)
    - [About ml-embedded-evaluation-kit](#about-ml-embedded-evaluation-kit)
    - [Start build](#start-build)
    - [Check build](#check-build)
    - [How to change build setting](#how-to-change-build-setting)
      - [Changing neural network sample](#changing-neural-network-sample)
      - [How to add and amend image samples](#how-to-add-and-amend-image-samples)
  - [Running Application](#running-application)
    - [Run](#run)
  - [User enhancement](#user-enhancement)
    - [About inference_runner](#about-inference_runner)
    - [Data Injection demo(experimental and supporting armclang only)](#data-injection-demoexperimental-and-supporting-armclang-only)
    - [Telnet to connect FVP](#telnet-to-connect-fvp)
    - [Adding network sample](#adding-network-sample)
    - [Build manually](#build-manually)
  - [Ethos-U Vela Model Optimizer](#ethos-u-vela-model-optimizer)
    - [Install Vela Optimizer](#install-vela-optimizer)
    - [Vela Optimizer Report](#vela-optimizer-report)
    - [Vela Optimizer Configuration Parameters](#vela-optimizer-configuration-parameters)
      - [1. Clock speed and memory configuration](#1-clock-speed-and-memory-configuration)
      - [2. MAC Unit change for FVP_Corstone_SSE-300_Ethos-U55](#2-mac-unit-change-for-fvp_corstone_sse-300_ethos-u55)
      - [3. MAC Unit](#3-mac-unit)
  - [Build and Run for FreeRTOS](#build-and-run-for-freertos)
    - [Build and Run for FreeRTOS](#build-and-run-for-freertos-1)
    - [How to add custom image and network for FreeRTOS](#how-to-add-custom-image-and-network-for-freertos)
      - [Converting a model](#converting-a-model)
      - [Converting a model](#converting-a-model-1)
  - [Modulate memory model with The Timing Adapter（Experimental）](#modulate-memory-model-with-the-timing-adapterexperimental)

<!-- /code_chunk_output -->

---
## Introduction

This kit uses Vela Optimizer based on a pre-prepared TensorFlow trained network, optimizes the layers of each network for Ethos-U55, makes scheduling, generates the tflile format, and converts a tflile-formatted network to a compilable Cpp. You can learn how to deploy the converted file in the application software and implement the compiled executable file in the Corstone-300 FVP and the FPGA subsystem using a sample network such as Mobilenet v2. You can also learn how to implement networks other than the sample applications. In addition, you can learn how to simulate Inference performance (cycle count) variation by FVP by changing the configuration such as on-chip SRAM, Flash, and MAC number of Ethos-U55.

---
## Preparation

The demo applications can be build with either the Arm Compiler (minimum version 6.14 required) or the GNU Arm Embedded Toolchain (minimum version 10.2.1 required).

* To use Arm Compiler (armclang), a standard license (paid) or a 30-day evaluation license (free) is required. You need to set the license path environment variable `ARMLMD_LICENSE_FILE` correctly. For the evaluation license, please refer [30-day free trial] (https://developer.arm.com/tools-and-software/embedded/arm-development-studio/evaluate).

When building the docker image the following packages will be downloaded to the root of this project

* ArmCompiler 6.16 for Linux64: [DS500-BN-00026-r5p0-18rel0.tgz](https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-18rel0.tgz)
* GNU Arm Embedded Toolchain: [gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)
* Corstore-300 FVP with Arm® Ethos™-U55 support for Linux64: [FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz](https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/MPS3/FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz)


### Contents and dependencies

This project contains the following dependencies.

* [Docker](https://www.docker.com/)
* [Tensorflow](https://github.com/tensorflow/tensorflow/)
* [CMSIS](https://github.com/ARM-software/CMSIS_5/)
* [FreeRTOS](https://github.com/aws/amazon-freertos.git) + [Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel.git)
* [vela](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela)
* [ethos-u driver and platform](https://review.mlplatform.org/ml/ethos-u)
* [ml-embedded-evaluation-kit](https://review.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit)
* [Corstone 300 FVP](https://developer.arm.com/ip-products/subsystem/corstone/corstone-300)

Models and Sample images used in this project are open source and the details can be found in the README.md of respective demo application.


---
## Setting up environment

The build scripts has been tested on CentOS7, Ubuntu 18.04, and Windows 10 PowerShell


### Option 1: Using Docker(Recommended)

0. Install Docker
    * Follow the instruction manual. https://docs.docker.com/get-docker/

1. Docker build on linux or Windows:
    * Windows PowerShell:
        * Using Arm Compile
            ```
            $> ./docker_build.PS1 -compiler armclang
            ```
        * Using GCC Compiler
            ```
            $> ./docker_build.PS1 -compiler gcc
            ```
    * Linux:
        * Using Arm Compiler
            ```
            $> ./docker_build.sh -c armclang
            ```
        * Using GCC Compiler
            ```
            $> ./docker_build.sh -c gcc
            ```

1. When the script has finished, you can find the image with this command
    ```
    $ docker images | grep "tensorflow-lite-micro-rtos-fvp"
    REPOSITORY                       TAG              IMAGE ID       CREATED          SIZE
    tensorflow-lite-micro-rtos-fvp   <compiler>       2729c3d6f35b   2 minutes ago   <size>
    ```

    * There may be some images with `<None>` tags present after the build. These are cache images, used for speeding up the build process. These images can be removed with the following command:
        ```commandline
        $ docker image prune -f
        ```
2. If you plan to use ArmCompiler, Make sure you have configured the Arm Compiler license and set the variables `$ARMLMD_LICENSE_FILE` and `$ARM_TOOL_VARIANT` accordingly.

3. On linux, Make sure you have configured the `$DISPLAY` environment variable correctly. This is needed to be able to open the GUI of the applications.

4. Enter the docker image using the following command:
    * Windows PowerShell:
        ```
        $ docker run --rm -it -e LOCAL_USER_ID=0 -e DISPLAY=<host-ip-address>:0.0 `
        -e ARMLMD_LICENSE_FILE=$env:ARMLMD_LICENSE_FILE `
        -e ARM_TOOL_VARIANT=$env:ARM_TOOL_VARIANT `
        --network host --privileged --rm tensorflow-lite-micro-rtos-fvp:<compiler> /bin/bash
        ```
        You can modify this command if you want to use shared volumes to share the repository/build folder between the host and docker (e.g. `-v $PWD\dependencies:/work/dependencies:rw`). For some Windows users this don't work properly, so if you have any build issues, try again without sharing the dependencies folder as a first step.

    * Linux:
        ```
        $> ./docker_run.sh -i <compiler>
        ```
        Other command line options:
        * -c : Send in a command to the docker container, such as 
            ```
            $ ./docker_run.sh -i <compiler> -c ./linux_build_rtos_apps.sh
            ```
        * --share_folder : share a folder between the docker container and the host pc, for easy file copying (images etc) between them.
            ```
            $ ./docker_run.sh -i <compiler> --share_folder share_folder
            ```

### Option 2: Using Linux console

***This has been tested on Ubuntu 18.04, 20.04 and CentOS7***

#### Setting up Linux environment

We use python for some scripts. So you need to install some dependencies.

1. Install Python and TkInter

    ```
    $ sudo apt install python3 python3-dev python3-venv python3-pip python3-tk
    ```

2. Verify that Python 3.6 or above is installed. Check your current installed version of Python by running:

    ```
    $ python3 --version
    Python 3.6.8
    ```

3. Create a python virtual environment

    ```
    $ python3 -m venv .pyenv-tflm
    ```

4. Install packages to the virtual environment
    
    ```
    $ source ./.pyenv-tflm/bin/activate
    $ pip install --upgrade pip setuptools
    $ pip install -r requirements.txt
    ```

5. Install CMake 3.15 or above
For the builds to work, CMake version 3.15 or above is needed. The scripts in this repository has been verified to work with CMake versions 3.15-3.20.


#### Install Arm Compiler

If you are choosing to use ArmCompler over GCC, follow these instructions for installation.

1. Install ArmCompiler and the Corstore-300 FVP.

    1. After installing, add armclang and the Corstore-300 directories to your PATH environment variable.
        * Temporary 
            ```
            $ export PATH=<armclang-install-dir>:$PATH
            $ export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
            ```
        * Persistent
            ```
            $ echo "export PATH=<armclang-install-dir>:$PATH" >> ~/.bashrc
            $ echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
            $ source ~/.bashrc
            ```

    2. You need to set the `ARMLMD_LICENSE_FILE` environment variable to point at a running license server in order to run armclang, and `ARM_TOOL_VARIANT` needs to be set to the Arm Compiler license variant.

    3. Before proceeding, it is essential to ensure that the following prerequisites have been fulfilled:

        - ArmCompiler version 6.14 or higher
            ```
            $ armclang --version
            Product: ARM Compiler 6.16 Professional
            Component: ARM Compiler 6.16
            ```
        - Corstone-300 FVP version 11.12 or higher
            ```
            $ FVP_Corstone_SSE-300_Ethos-U55 --version
            Fast Models [11.14.24 (Mar 23 2021)]
            Copyright 2000-2021 ARM Limited.
            All Rights Reserved.
            ```

If you have any issues, make sure your PATH is configured correctly, and that you have the `ARMLMD_LICENSE_FILE` and `ARM_TOOL_VARIANT` configured correctly.

* To use Arm Compiler (armclang), a standard license (paid) or a 30-day evaluation license (free) is required. You need to set the license path environment variable `ARMLMD_LICENSE_FILE` correctly. For the evaluation license, please refer [30-day free trial] (https://developer.arm.com/tools-and-software/embedded/arm-development-studio/evaluate).


#### Install Arm GNU toolchain

If you choose to use GCC over ArmCompiler, follow these instructions to install.

1. Install [Arm GNU toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) by extracting to a folder on your system and the Corstore-300 FVP.

    1. After installing, add gcc and the Corstore-300 directories to your PATH environment variable.
        * Temporary 
            ```
            $ export PATH=<gcc-install-dir>:$PATH
            $ export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
            ```
        * Persistent
            ```
            $ echo "export PATH=<gcc-install-dir>:$PATH" >> ~/.bashrc
            $ echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
            $ source ~/.bashrc
            ```
    2. Check that PATH configured correctly
        ```
        $ arm-none-eabi-gcc --version
        arm-none-eabi-gcc (GNU Arm Embedded Toolchain 10-2020-q4-major) 10.2.1 20201103 (release)
        ```
        ```
        $ FVP_Corstone_SSE-300_Ethos-U55 --version
        Fast Models [11.14.24 (Mar 23 2021)]
        Copyright 2000-2021 ARM Limited.
        All Rights Reserved.
        ```

If you have any issues, make sure your PATH is configured correctly.

##About the Demo Applications
This project aims to support building applications using either the [ml-embedded-evaluation-kit repository](https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/) or the [ethos-u repository](https://git.mlplatform.org/ml/ethos-u/ethos-u.git/about/).

### ethos-u repository
This is the root repository for all Arm® Ethos™-U software. It is provided to help users download required repositories and place them in a tree structure.

It comes with a couple of basic demo applications running on the Corstone-300 (Cortex-M55 + Ethos-U55) platform. The demo applications has support for FreeRTOS, as well as bare-metal.

- More information about the repository
[https://git.mlplatform.org/ml/ethos-u/ethos-u.git/tree/README.md](https://git.mlplatform.org/ml/ethos-u/ethos-u.git/tree/README.md)
- More information about the Arm Ethos-U 
[https://developer.arm.com/ip-products/processors/machine-learning/arm-ethos-u](https://developer.arm.com/ip-products/processors/machine-learning/arm-ethos-u)

In the `sw/ethos-u` folder of this repository, there are a couple of additional samples, with FreeRTOS support, that can be built using the ethos-u repository as a base.

### ml-embedded-evaluation-kit repository
This repository is for building and deploying Machine Learning (ML) applications targeted for Arm Cortex-M and Arm Ethos-U NPU.

To run evaluations using this software, we suggest using an [MPS3 board](https://developer.arm.com/tools-and-software/development-boards/fpga-prototyping-boards/mps3) or a fixed virtual platform (FVP) that supports Ethos-U55 software fast model. Both environments run a combination of the new [Cortex-M55 processor](https://www.arm.com/products/silicon-ip-cpu/cortex-m/cortex-m55) and [Ethos-U55 NPU](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u55).

The following sample applocations are available in the ml-embedded-evaluation-kit:

* ad (Anomaly Detection)
* asr (Automatic Speech Recognition)
* img_class (Imange Classification)
* inference_runner (Run any quantized tflite network)
* kws_asr (Keyword Spotting and Automatic Speech Recognition)
* kws (Keyword Spotting)

There is an additional person_detection sample in the `sw/ml-eval-kit` folder of this repository.
For more information about `inference_runner`, refer [User Enhancement](#User Enhancement).

---
## Building Applications

### About ml-embedded-evaluation-kit

[ml-embedded-evaluation-kit](https://review.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit) contains demo applications, build environment, and sample images for evaluating the Arm Ethos-U55 NPU. The applications can run with either the FVP or directly on the MPS3 evaluation board. Tshi section provides the guide of using ml-embedded-evaluation-kit for build, run and evaluate the demo applications.


### Start build

The script `linux_build_eval_kit_apps.sh` will download and build the evaluation kit applications. First step is to build by using `img_class`(MobileNet v2). 

```commandline
$ ./linux_build_eval_kit_apps.sh
```
`linux_build_eval_kit_apps.sh` option
* `--compiler`　to select which compiler to build with.
* `--num_macs`　to select the mac configuration to use {32,64,128 or 256}.
* `--model　<path/to/quantized/model.tflite>`  to select networks
* `--use_case`　to select which use case to build. if you want to evaluate the performance of a custom network, select `--use_case inference_runner` and provide the network as `--model <path/to/quantized/model.tflite>`. For more information about `inference_runner`, refer [User Enhancement](#User Enhancement).
* `--help`　to see all command line options.

### Check build

After the build, make sure the AXF image file is created. 
`dependencies/ml-embedded-evaluation-kit/build-docker/bin/ethos-u-img_class.axf`

A build log file is dumped to `dependencies/log`, which includes [Vela Optimizer Report](#vela-optimizer-report). 

### How to change build setting
This section describes how to change build setting from default configuration.

#### Changing neural network sample
In addition to `img_class` default application, the following sample applications are available in the ml-embedded-evaluation-kit.

- ad (Anomaly Detection)
- asr (Automatic Speech Recognition)
- img_class (Imange Classification, MobileNet v2)
- inference_runner (Run any quantized tflite network)
- kws_asr (Keyword Spotting and Automatic Speech Recognition)
- kws (Keyword Spotting)

There is an additional person_detection sample in `sw/ml-eval-kit` folder of this repository. Find each models' description in `dependencies/ml-embedded-evaluation-kit/docs/use_cases`. 

For more information about `inference_runner`, refer [User enhancement](#user-enhancement).

#### How to add and amend image samples
This kit contains image samples. In order to use new image data, add the data file in the sample folder. 

- Add image data for Person Detection: 
`sw/ml-eval-kit/samples/resources/person_detection/samples/`
- Add image data for img_class: 
`dependencies/ml-embedded-evaluation-kit/resources/img_class/samples/`
- Add image data for other models: 
`dependencies/ml-embedded-evaluation-kit/resources/<use_case>/samples/`


---
## Running Application
Run the binary file built at previous section [Building Applications](#Building Applications)

### Run
- Running on Docker container:
    ```commandline
    $ FVP_Corstone_SSE-300_Ethos-U55 \
    -a dependencies/ml-embedded-evaluation-kit/build-docker/bin/ethos-u-img_class.axf
    ```
- Running on Linux Host:
    ```commandline
    $ FVP_Corstone_SSE-300_Ethos-U55 \
    -a dependencies/ml-embedded-evaluation-kit/build/bin/ethos-u-img_class.axf
    ```

FVP utilizes X11 Windows as default setting. If you have DISPLAY issues due to X11 window, you can use the following command to run the demo without GUI:
- Run FVP without GUI:
    ```commandline
        $ FVP_Corstone_SSE-300_Ethos-U55 \
            -C mps3_board.visualisation.disable-visualisation=1 \
            -C mps3_board.uart0.out_file=- \
            -C mps3_board.telnetterminal0.start_telnet=0 \
            -C mps3_board.uart0.unbuffered_output=1 \
            -C mps3_board.uart0.shutdown_on_eot=1 \
            -C mps3_board.uart0.shutdown_tag="releasing platform" \
            -a dependencies/ml-embedded-evaluation-kit/build/bin/ethos-u-img_class.axf
    ```

When X11 Window is used, the following FVP Window and Telnet Window will be started by the execution command. When you select the item you want to infer from the Telnet Window, FVP starts the inference. And, when the inference ends, the result is displayed. 

![Running ethos-u-img_class.axf](res/FDv21.05-img_class.png)

---
## User enhancement
In addition to the sample network models, you can use the `inference_runner` to incorporate new models into the application and run it on FVP or FPGA, as long as it is quantitized tflile network.      
You can also change MAC/Cycle number of Ethos-U55, affecting to inference cycle count. 
Data injection feature (experimental feature) is useful to integrate the demo for auto test envuronment.   

### About inference_runner
`inference_runner` is a front-end development tool for importing user-created tflite-format networks into Vela Optimizer. As an example, the [Inference Runner Code Sample](dependencies/ml-embedded-evaluation-kit/docs/use_cases/inference_runner.md) gives a simple usage. This can be used as a reference. For detail on how to use it, refer `dependencies/ml-embedded-evaluation-kit/docs/use_cases/inference_runner.md`. 

### Data Injection demo(experimental and supporting armclang only)
The kit provided is structured to build both the image to be inferred and the inference network model to perform the inference. It is necessary to rebuild in case of adding a new image after building. 

In order to avoid this restriction, there is a function to add an image used for inference even after build by overwriting (data injection) the memory area that stores the binary used by FVP from outside FVP. This feature is typically implemented with the `--data FILE@ADDRESS` option, which is a standard feature of FVP. As an application example of data injection, it is conceivable to allocate the image data in the host side folder or the image data from USB WebCam to the FVP memory area, and perform sequential inference by FVP. This method separates the execution environment of the inference network model and the image to be inferred, so that it enables to be incorporated into automatic verification using a cloud environment.

Data Inject can be perforamed for two sample cases (person_detection/img_class) by using `data_injection_demo.py`.

_This script runs properly with armclang only, and has an issue with gcc_

- Runnig on Dokcer container:
    ```
    $ source .pyenv-tflm/bin/activate
    $ ./data_injection_demo.py
    ```
- Running on Linux Host:
    ```commandline
    $ source .pyenv-tflm/bin/activate
    $ ./data_injection_demo.py
    ```
`data_injection_demo.py` option
 * `--image_path=<path/to/image/or/folder>` Select the Images to inject into the demo applications

 * `--enable_camera` Inject still image data from an USB camera. To perform inference on a video stream, the best way would be to convert the video frames into still images. It is not possible to inject video stream directly.
 
 * `--help` Show all command line options.

When running the inference by Data injection mode, a window, like below, will open to show the (a)inference result, (b)memory read/write count and (c)NPU cycle count.

![Python App Results](res/python-app-res.png)


### Telnet to connect FVP
Telnet can access to FVP runnig Sample demo application. Launch terminal and connect from Telnet. 

```commandline
$ telnet localhost 5000
```

When using Docker, Attache to Docker container first, then start Telent connection. 

```commandline
$ docker ps
$ docker exec -it <container-id> /bin/bash
```

For more information about FVP's Telnet feature, refer [Fast Models Fixed Virtual Platforms (FVP) Reference Guide](https://developer.arm.com/documentation/100966/latest/)

### Adding network sample

Add the custom network with refercen to denmo application structure in ml-embedded-evaluation-kit. 

The person_detection demo stored in sw/ml-eval-kit/samples/source/use_case/person_detection is a derivative of the img_class use case. It facilitates to develop the custom demonstration by using same structure. 

### Build manually

The demo application is a warpper library of Arm ml-emedded-evaluation-kit. It is also possibe to use [ml-emedded-evaluation-kit](`https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git`) directly, not via warpper function. The Docker container used by demo application is complient with ml-emedded-evaluation-kit guideline. 

---
## Ethos-U Vela Model Optimizer

Vela is a tool for optimizing neural networks prepared by TensorFlow Lite for Microcontroller (TFLM) for Arm Ethos-U NPU, and is provided as open source. In order to bring out the performance of Ethos-U NPU, the neural network must be quantized to `(u) int 8` or` (u) int 16` in advance. Check out the latest project [ethos-u-vela project] (https://pypi.org/project/ethos-u-vela/) for supported Tensor FLow versions.


Use Vela like this:<br>
```commandline
$ vela <input_model.tflite>
```
Vela Optimizer log report is stored in `output`.

### Install Vela Optimizer

[ethos-u-vela project] (https://pypi.org/project/ethos-u-vela/) can be installed from pip. The source code and old versions are accessible from [ethos-u/ethos-u-vela.git] (https://git.mlplatform.org/ml/ethos-u/ethos-u-vela.git/) .

- System requirement
Python v3.6 or above. (using virtualenv is recommended)

- Setting up Python:
    ```commandline
    $ sudo apt update
    $ sudo apt install -y python3 python3-venv python3-dev python3-pip
    ```

- Vela install with virtualenv
    ```commandline
    $ python3 -m venv .pyenv-tflm
    $ source ..pyenv-tflm/bin/activate
    $ python -m pip install ethos-u-vela
    ```

### Vela Optimizer Report

Vela Optimizer reports the static analysis results when the optimization is performed. You can use this report to estimate some performance before running the binary on an FVP or MPS3 FPGA Prototype board. For example, take a look at the `img_class` (MobileNet v2) report used by default.

1. The SRAM size required to run the network and the binary size of the network stored in non-volatile memory (including the U55 driver) are estimated as follows.

    ```
    Total SRAM used                    638.62KiB
    Total Off0chip Flash used         3139.81KiB
    ```

2. You can check the ratio of whether the operators included in the network are executed by U55 or Host Processor Cortex-M55(Operator falling back). Since MobileNet v2 included in the sample is a network pre-tuned so that all operators are mapped to U55, Falling back is reported to be `0%` even after running Vela Optimizer. The ideal Falling back value is `0%`. If the number of falling backs increases, it means that data is frequently passed between the U55 and Host CPU when executing inference, which may cause a decrease in execution performance.

    ```
    0/238 (0.0%) operations falling back to the CPU
    ```

3. Vela reports statically expected inference/s based on conditions such as memory bandwidth, U55 clock frequency, and number of MACs. It is also possible to change the conditions with [Vela Optimizer configuration parameters] (# vela-optimizer configuration-parameters).

    ```
    Batch Inference time       14.46 ms, 69.14 inference/s (batch size 1)
    ```

### Vela Optimizer Configuration Parameters

Various parameters can be set in Vela Optimizer. By setting parameters, it is possible to statically estimate the approximate U55 execution performance at the time of network optimization. Click here for a sample configuration file.
`./dependencies\ml-embedded-evaluation-kit\scripts\vela\default_vela.ini`

By modifying this file or creating a new one, you can give Vela Optimizer the features of the U55 and its memory system.

#### 1. Clock speed and memory configuration

In the configuration file, the U55 operating frequency `core_clock` is set to 500MHz by default. This parameter is used by Vela Optimizer to statically estimate U55 execution performance.

By giving the memory configuration at Vela compile time, it is possible to estimate the performance dependency due to the memory bandwidth. The parameters `Sram_clock_scale` and` OffChipFlash_clock_scale` determine the access cycle to SRAM connected to the AXI-M0 bus and FLASH (nonvolatile memory) connected to AXI-M1 by the `core_clock` ratio, respectively. The U55's AXI-M0 and AXI-M1 buses each have a 64-bit-AXI5 data width. The default value gives Vela Optimizer `4 GB/s` SRAM bandwidth and` 0.5 GB/s` FLASH bandwidth.

However, these parameters are only used when statically estimating U55 execution performance with Vela Optimizer and do not affect the optimization results. If you want to reflect the memory model in the execution result, please consider using [Memory model optimization using timing adapter (experimental function)] (#Memory model optimization experimental function using timing adapter).

#### 2. MAC Unit change for FVP_Corstone_SSE-300_Ethos-U55
The MAC Unit used by FVP_Corstone_SSE-300_Ethos-U55 can be changed in the FVP runtime options. The default value is set to `128`.

```commandline
$  FVP_Corstone_SSE-300_Ethos-U55 -l | grep ethosu.num_macs
```

For example, if you want to change the MAC Unit to 256, add the following settings to the FVP runtime options.

```commandline
$ FVP_Corstone_SSE-300_Ethos-U55 \
    -C ethosu.num_macs=256
```

#### 3. MAC Unit
Vela Optimizer assumes that the Ethos-U55 MAC is set to `128` as default.
On the other hand, with Ethos-U55 IP, it is possible to select the MAC Unit from 32,64,128,256 (MAC/cycle) as a logic synthesis option. Therefore, when changing the Ethos-U55 MAC Unit configuration of the actual machine or FVP from the default value `128`, it is necessary to set the Vela Optimizer configuration parameter at the same time. In that case, use the `--accelerator-config` option.

- `--accelerator-config`: 
    `ethos-u55-256`, `ethos-u55-128`(default),`ethos-u55-64`,`ethos-u55-32`


For more technical details on Vela Optimizer, see Vela Documentation (https://git.mlplatform.org/ml/ethos-u/ethos-u-vela.git/about/) and Vela command line example (https: /) Please check /git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/tree/docs/sections/building.md#optimize-custom-model-with-vela-compiler).

Vela Optimizer technical details are available in [Vela Documentation](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela.git/about/) and [Vela command line example](https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/tree/docs/sections/building.md#optimize-custom-model-with-vela-compiler).

---
## Build and Run for FreeRTOS
FreeRTOS environment is prepared for some demos. It can be run on FreeRTOS using an both FVP or MPS3 FPGA Prototype board.

### Build and Run for FreeRTOS
1. Build FreeRTOS
    ```commandline
    $ ./linux_build_rtos_apps.sh -c <compiler>
    ```

1. Run person_detection
    ```commandline
    $ ./run_demo_app.sh 
    ```

    * Default sample is `person_detection`. Built Sample and libraries are stored under `dependencies/ethos-u/build/bin/`,`dependencies/ethos-u/build/applications/`.


1. 実行結果の分析<br>
    1. [Person Detection](sw/ethos-u/samples/person_detection/README.md#run-application-with-fvp)
    1. [Hello TFLM](sw/ethos-u/samples/hello_tflm/README.md#run-application-with-fvp)
    1. [Mobilenet V2](sw/ethos-u/samples/mobilenet_v2/README.md#run-application-with-fvp)

### How to add custom image and network for FreeRTOS

TensorFlow Lite for Microcontoller models (.tflite) and images must be converted to a compilable format with armclang/gcc and built with the source included. Scripts are provided to help with the conversion.

* Docker: 
    `/usr/local/convert_scripts`
    
* Linux: 
    `scripts/convert_scripts`




#### Converting a model

`convert_tflite_to_cpp.sh` converts a network in tfile format to compilable Cpp.

```commandline
$ convert_tflite_to_cpp.sh --input <model.tflite> --output model_vela.cpp
```

After conversion, copy it to the build folder (i.e., `sw/ethos-u/samples/mobilenet_v2`) and rebuild.

#### Converting a model

`convert_images_to_cpp.sh` converts RGB or Grayscale format image data to compilable Cpp.

- RGB format:
    ```commandline
    $ convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height>
    ```
- Grayscale format:
    ```commandline
    $ convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height> \
        --grayscale 1
    ```

After conversion, copy it to the build folder (i.e., `sw/ethos-u/samples/mobilenet_v2`) and rebuild.

---
## Modulate memory model with The Timing Adapter（Experimental）

The Timing Adapter is a software library for evaluating the dependency of the U55 memory model on execution performance. Please use it after understanding that it is an ***experimental*** function.

By modulating the memory access cycle, the timing adapter reproduces the system performance when using embedded memory with different characteristics such as TCM/In-SRAM/FLASH/MRAM. It is provided as a software library for Cortex-M and is implemented at compile time, so it is independent of hardware platforms such as FVP or MPS3 FPGA. However, it is an ***invasive debug*** function because it is necessary to add a software library to the system to reproduce the memory access.

Ethos-U55 has two AXI ports (M0, M1), M0 has Read-Write function, and M1 has Read-Only function. The timing adapter can be set individually for the behavior of M0 and M1.

* AXI0-M0 is used for RAM access. The default settings are read/write latancy = `32 cycles`, bandwidth =` 4 GB/s`.
* AXI1-M1 is used for FLASH (or non-volatile memory) access. The default settings are read/write latancy = `64 cycles`, bandwidth =` 0.5 GB/s`.

- Timing Adapter Configuration file: 
    `./dependencies/ml-embedded-evaluation-kit/scripts/cmake/ta_config.cmake`

Read/Write latency on the AXI bus is changed with `TAx_RLATENCY`,` TAx_WLATENCY`.
The Read/Write bandwidth on the AXI bus is changed with `TAx_PULSE_ON`,` TAx_PULSE_OFF`, and `TAx_BWCAP`.

For exmaple:
```
BW_multiplier = TAx_BWCAP / (TAx_PULSE_ON + TAx_PULSE_OFF)
BW = BW_multiplier * 4 GB/s
```

As a result, the default SRAM is set to `BW_multiplier = 1`. The memory bandwidth at that time is `4 GB/s`. The default FLASH is set to `BW_multiplier = 0.125`. The memory bandwidth at that time is `0.5 GB/s`. If you want to set the bandwidth to `0.25 GB/s`, set it to` BW_multiplier = 0.0625`.

For example: 
```
TAx_BWCAP=25
TAx_PULSE_ON=320
TAx_PULSE_OFF=80
```

Technical details about Timing Adapter: 
[Timing Adapter Documentation](https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git/tree/docs/sections/building.md#building-timing-adapter-with-custom-options) 

---
