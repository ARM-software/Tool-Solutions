# Tensorflow Lite for Microcontrollers on Corstone 300 FVP (Cortex-M55 + Ethos-U55)

These instructions are available in the following languages
    
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" width="15" height="15" alt="English" style="vertical-align:middle" /> English](README.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" width="15" height="15" alt="Japanese" style="vertical-align:middle" /> 日本語](README-ja.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/83/Sweden-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/83/Sweden-orb.png" width="15" height="15" alt="Swedish" style="vertical-align:middle" /> Svenska](README-sv.md) 

## Introduction

This repository contains instuctions and scripts for setting up an environment running an Corstone SSE-300 FVP (Fixed Virtual Platform). The FVP simulates a Cortex-M55 and Ethos-U55 (µNPU) platform. 

You can choose to setup the environment using Docker or on a linux machine.

The repository includes a couple of example applications running on FreeRTOS to get started with developing applications for a Cortex-M and Ethos-U platform.

## Table of Contents


* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Dependencies](#dependencies)
* [Setup Environment](#setup-environment)
    * [Option 1: Using Docker (Recommended)](#option-1-using-docker-recommended)
    * [Option 2: Using local linux machine.](#option-2-using-local-linux-machine)
* [Build demo applications](#build-demo-applications)
    * [ml-embedded-evaluation-kit](#ml-embedded-evaluation-kit)
    * [Ethos-U RTOS samples](#ethos-u-rtos-samples)
* [About the Demo Applications](#about-the-demo-applications)
    * [Person Detection](#person-detection)
    * [Mobilenet](#mobilenet)
    * [Other samples](#other-samples)
* [Vela Model Optimizer for Ethos-U](#vela-model-optimizer-for-ethos-u)
    * [Installing Vela](#installing-vela)
* [Convert models and Images to cpp code](#convert-models-and-images-to-cpp-code)
    * [Converting a model](#converting-a-model)
    * [Converting a folder with images](#converting-a-folder-with-images)

## Prerequisites

* You need to set the `ARMLMD_LICENSE_FILE` environment variable to point at a running license server in order to run armclang. Do this before building the docker image.

When building the docker image the following packages will be downloaded to the root of this project:

* [DS500-DN-00026-r5p0-18rel0.tgz](https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-18rel0.tgz?revision=2fde4f61-f000-4f22-a182-0223543dc4e8?product=Download%20Arm%20Compiler,64-bit,,Linux,6.15) (ArmCompiler 6.16 for Linux64)
* [FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz](https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz) (Corstore SSE-300 FVP with Ethos U55 support for Linux64)

## Dependencies

This project has the following dependencies:

* [Docker](https://www.docker.com/)
* [Tensorflow](https://github.com/tensorflow/tensorflow/)
* [CMSIS](https://github.com/ARM-software/CMSIS_5/)
* [FreeRTOS](https://github.com/aws/amazon-freertos.git) + [Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel.git)
* [vela](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela)
* [ethos-u platform](https://review.mlplatform.org/ml/ethos-u/ethos-u)
* [ml-embedded-evaluation-kit](https://review.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit)

Models and Sample images used in this project are open source and the details can be found in the README.md of respective demo application.

## Setup Environment

The build scripts has been tested on CentOS7, Ubuntu 18.04, and Windows 10 PowerShell

### Option 1: Using Docker (Recommended)

0. Install Docker
    * Windows: https://docs.docker.com/docker-for-windows/install/
    * Linux: https://docs.docker.com/engine/install/

1. Run the docker build script in a linux terminal or Windows Powershell:
    * Windows PowerShell:
        * If you wish to use the Arm Compiler
            ```
            $> ./docker_build.PS1 -compiler armclang
            ```
        * If you wish to use the GNU GCC Compiler (Not available for ml-embedded-evaluation-kit)
            ```
            $> ./docker_build.PS1 -compiler gcc
            ```
    * Linux:
        * If you wish to use the Arm Compiler
            ```
            $> ./docker_build.sh -c armclang
            ```
        * If you wish to use the GNU GCC Compiler (Not available for ml-embedded-evaluation-kit)
            ```
            $> ./docker_build.sh -c gcc
            ```

1. When the script has finished, there should be a Docker image called tensorflow-lite-micro-rtos-fvp:<compiler>.

1. Enter the docker image using the following command (you can modify the command if you want to use local volumes etc.):
    * Windows:
        ```
        $> docker run -it -e LOCAL_USER_ID=0 -v $PWD\sw:/work/sw -v $PWD\dependencies:/work/dependencies -e DISPLAY=localhost:1 --privileged --rm tensorflow-lite-micro-rtos-fvp:<compiler> /bin/bash
        ```
    * Linux:
        ```
        $> ./docker_run.sh -i <compiler>
        ```

### Option 2: Using local linux machine.

***This has been tested on Ubuntu 18.04 and CentOS7 ***

1. Install ArmCompiler and the Corstore SSE-300 FVP.

    1. After installing, add armclang and the Corstore SSE-300 directories to your PATH environment variable.
        * Temporary 
        ```
        $> export PATH=<armclang-install-dir>:$PATH
        $> export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
        ```
        * Persistent
        ```
        $> echo "export PATH=<armclang-install-dir>:$PATH" >> ~/.bashrc
        $> echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
        $> source ~/.bashrc
        ```
    1. Check that PATH configured correctly

        ```
        $> armclang --version
        Product: ARM Compiler 6.16 Ultimate
        Component: ARM Compiler 6.16
        Tool: armclang [5dd79400]

        Target: unspecified-arm-none-unspecified

        $> FVP_Corstone_SSE-300_Ethos-U55 --version

        Fast Models [11.14.24 (Feb  2 2021)]
        Copyright 2000-2021 ARM Limited.
        All Rights Reserved.

        Info: /OSCI/SystemC: Simulation stopped by user.
        ```

    If you have any issues, make sure your PATH is configured correctly, and for armclang, that you have the `ARMLMD_LICENSE_FILE` configured correctly.

## Build demo applications

### ml-embedded-evaluation-kit

This kit include baremetal sample applications.
The applications can run with either the FVP or directly on the MPS3 evaluation board.

There are two scripts that can be used for building the sample application. 

* `run_fvp_eval.py` will download, build and run the person_detection/img_class sample applications. Use this for an example of how to inject data dynamically into the application. 
    ```
    $> ./run_fvp_eval.py
    ```
    * Images to inject into the application can be selected using the command line argument `--image_path=<path/to/image/or/folder>`
    * It is also possible use a USB camera to get the input data by using the option `--use_camera=True` (Each inference takes at least 10 seconds, so don't expect a smooth real time video)
    * To perform inference on a video stream, the best way would be to convert the video frames into still images and use the frames as input

* `linux_build_eval_kit.sh` will download and build the kit, use this if you want to manually run the samples or if you want to bake your own sample images into the application for running on the MPS3 board. Copy your images into the `sw/ml-eval-kit/samples/resources/<use-case>/samples/` folder before running the build script.
    1. Build
        ```
        $> ./linux_build_eval_kit.sh
        ```

    1. Run sample
        ```
        $> FVP_Corstone_SSE-300_Ethos-U55 -a dependencies/ml-embedded-evaluation-kit/build_auto/bin/<sample-name>.axf
        ```
    1. Interact with the sample
        Somtimes you need to interact with the sample applications.
        To do this, please open a second terminal and run
            ```
            $> telnet localhost 5000
            ```

        * NOTE: When you are using docker, you need to enter the running docker container in the second terminal first:
            * Find the docker container-id of the running container
                ```
                $> docker ps
                ```
            * Enter the docker container
                ```
                $> docker exec -it <container-id> /bin/bash
                ```

It is also possible to manually build and run the ml-emedded-evaluation-kit by following the instructions for that project separately. The open source project is available here: `https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git`

### Ethos-U RTOS samples
These applications are FreeRTOS sample applications and can run with either the FVP or directly on the MPS3 evaluation board.

1. Build
    ```
    $> ./linux_build.sh -c <compiler>
    ```

1. Run sample
    ```
    $> ./run_demo_app.sh 
    ```

## About the Demo Applications
### Person Detection
The demo application is running a person detection network based on mobilenet, running on FreeRTOS.
Two inference is performed on an image with a person in it and one without.

The demo application is meant to show a simple example of how you can deploy Tensorflow Lite Micro on a Corstore SSE-300 platform.  

### Mobilenet
The demo application is running a mobilenet network, running on FreeRTOS.
Two inferences are performed on an image with a bicycle in it, and one with women wearing kimono.

The demo application is meant to show a simple example of how you can deploy Tensorflow Lite Micro on a Corstore SSE-300 platform. 

### Other samples
The ml-embedded-evaluation-kit contains sample applications for keyword spotting and natural language processing.
You can run these samples manually.

## Vela Model Optimizer for Ethos-U

Vela is installed in the docker image, making it possible to compile you own models.

Use vela like this:
```
vela <input_model.tflite>
```
The result is a compiled tflite model in the `output` folder.

### Installing Vela

Vela is available as a python package. Here are instructions on how to install. 

1. Prerequisites
    You will need to have python v3.6 or above. 
    We recommend using a virtualenv.

    Installing Python:
    ```
    $> sudo apt update
    $> sudo apt install -y python3 python3-venv python3-dev python3-pip
    ```

1. Install Vela on the virtualenv

    ```
    $> python -m virtualenv -p python3 .vela-venv
    $> source .vela-venv/bin/activate
    $> python -m pip install ethos-u-vela
    ```

## Convert models and Images to cpp code

There are helper scripts available to convert tflite models and images to cp code.

They are located in `~/work/sw/convert_scripts`

### Converting a model

Use the `convert_tflite_to_cpp.sh` script to convert a tflite model to cpp code.

```
$> convert_tflite_to_cpp.sh --input <model.tflite> --output model_vela.cpp
```

After converting the model, you can add it to the project folder, and recompile.  

### Converting a folder with images

- For RGB images:
    ```
    $> convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height>
    ```
- For Grayscale images:
    ```
    $> convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height> \
        --grayscale 1
    ```

Add the resulting code files to the project, and recompile.
