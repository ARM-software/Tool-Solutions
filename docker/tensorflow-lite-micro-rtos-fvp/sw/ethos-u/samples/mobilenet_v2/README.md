# Mobilenet V2 demo

## Introduction

This demo can classify what is in an image. It can recognize 1000 classes

The input image is RGB (3 channels) with a resolution of 224x224 pixels.

The output is an array of 1001 values, representing the confidences that the image contains 
the object (+one for empty). 

## Table of Contents

* [Introduction](#introduction)
* [Resources](#resources)
    * [Model](#model)
    * [Images](#images)
* [Build](#build)
* [Run application with FVP](#run-application-with-fvp)
    * [Inference results](#inference-results)
    
## Resources

Here is a list of the resources used in this application

### Model
The model is Mobilenet V2, from the Arm Public ML-zoo. 
It can be accessed from the link below

* https://github.com/ARM-software/ML-zoo/tree/master/models/image_classification/mobilenet_v2_1.0_224/tflite_uint8 

### Images

The `samples` folder contain the images used in this project.

The sample images used in this project are under the CC license
The originals can be found here:
* https://upload.wikimedia.org/wikipedia/commons/3/32/POV-cat.jpg
* https://upload.wikimedia.org/wikipedia/commons/1/18/Dog_Breeds.jpg
* https://upload.wikimedia.org/wikipedia/commons/2/2a/Bonnie_and_Clyde_Movie_Car.JPG
* https://upload.wikimedia.org/wikipedia/commons/c/c4/Summer_Bicycle.JPG
* https://upload.wikimedia.org/wikipedia/commons/f/f8/JP-Kyoto-kimono.jpg


## Build

The demo application is build with the cmake build system and
uses armclang as a compiler by default. 

Build by using the following commands

```
$> mkdir build
$> cd build
$> cmake ..
$> make
```

The result will be an application called `freertos_mobilenet_v2.elf`.

## Run application with FVP

You can run the demo with FVP_Corstone_SSE-300_Ethos-U55.

Downloadable for free from the link below:
* https://developer.arm.com/tools-and-software/open-source-software/arm-platforms-software/arm-ecosystem-fvps

Run with the following command:

```
FVP_Corstone_SSE-300_Ethos-U55  \
    --stat \
    -C mps3_board.visualisation.disable-visualisation=1 \
    -C mps3_board.uart0.out_file=- \
    -C mps3_board.telnetterminal0.start_telnet=0 \
    -C mps3_board.uart0.unbuffered_output=1 \
    -C mps3_board.uart0.shutdown_tag="EXITTHESIM" \
    -C cpu0.CFGITCMSZ=14 \
    -C cpu0.CFGDTCMSZ=14 \
    -C ethosu.num_macs=128 \
    -a freertos_mobilenet_v2.elf
```

### Inference results

You will see some info messages from the npu, along with the result from the inference.

The inference result looks like this:
```
        #-------------------
        Top prediction for Summer_Bicycle
        label: mountain bike, all-terrain bike, off-roader
        ID: 672  : Confidence: 10.779286 
        #-------------------
```

The complete application output will look something like this in a successful run:

```
telnetterminal0: Listening for serial connection on port 5000
telnetterminal1: Listening for serial connection on port 5001
telnetterminal2: Listening for serial connection on port 5002
telnetterminal5: Listening for serial connection on port 5003

Info: FVP_MPS3_Corstone_SSE_300: Creating Ethos-U55 with config H128

    Ethos-U rev 074befff --- Nov 25 2020 17:22:52
    (C) COPYRIGHT 2019-2020 Arm Limited
    ALL RIGHTS RESERVED

ethosu_init_v4. base_address=48102000, fast_memory=31000000, fast_memory_size=655360, secure=1, privileged=1
ethosu_register_driver: New NPU driver at address 30001d20 is registered.
Soft reset NPU
Sending inference job
Received inference job. job=30073fc0, name=Summer_Bicycle
Running inference job: Summer_Bicycle
ethosu_find_and_reserve_driver - Driver 30001d20 reserved.
ethosu_invoke_v3
ethosu_invoke OPTIMIZER_CONFIG
handle_optimizer_config:
Optimizer release nbr: 0 patch: 1
Optimizer config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Optimizer config Ethos-U version: 1.0.6
Ethos-U config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Ethos-U version: 1.0.6
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke COMMAND_STREAM
handle_command_stream: cmd_stream=703b8110, cms_length 19998
ethosu_release_driver - Driver 30001d20 released
arena_used_bytes : 482348

        #-------------------
        Top prediction for Summer_Bicycle
        label: mountain bike, all-terrain bike, off-roader
        ID: 672  : Confidence: 10.779286 
        #-------------------

Finished running job: Summer_Bicycle
Received inference job response. status=0
Sending inference job
Received inference job. job=30073fc0, name=POV_cat
Running inference job: POV_cat
ethosu_find_and_reserve_driver - Driver 30001d20 reserved.
ethosu_invoke_v3
ethosu_invoke OPTIMIZER_CONFIG
handle_optimizer_config:
Optimizer release nbr: 0 patch: 1
Optimizer config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Optimizer config Ethos-U version: 1.0.6
Ethos-U config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Ethos-U version: 1.0.6
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke COMMAND_STREAM
handle_command_stream: cmd_stream=703b8110, cms_length 19998
ethosu_release_driver - Driver 30001d20 released
arena_used_bytes : 482348

        #-------------------
        Top prediction for POV_cat
        label: Egyptian cat
        ID: 286  : Confidence: 9.098114 
        #-------------------

Finished running job: POV_cat
Received inference job response. status=0
Sending inference job
Received inference job. job=30073fc0, name=JP_Kyoto_kimono
Running inference job: JP_Kyoto_kimono
ethosu_find_and_reserve_driver - Driver 30001d20 reserved.
ethosu_invoke_v3
ethosu_invoke OPTIMIZER_CONFIG
handle_optimizer_config:
Optimizer release nbr: 0 patch: 1
Optimizer config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Optimizer config Ethos-U version: 1.0.6
Ethos-U config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Ethos-U version: 1.0.6
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke COMMAND_STREAM
handle_command_stream: cmd_stream=703b8110, cms_length 19998
ethosu_release_driver - Driver 30001d20 released
arena_used_bytes : 482348

        #-------------------
        Top prediction for JP_Kyoto_kimono
        label: kimono
        ID: 615  : Confidence: 19.481831 
        #-------------------

Finished running job: JP_Kyoto_kimono
Received inference job response. status=0
Sending inference job
Received inference job. job=30073fc0, name=Dog_Breeds
Running inference job: Dog_Breeds
ethosu_find_and_reserve_driver - Driver 30001d20 reserved.
ethosu_invoke_v3
ethosu_invoke OPTIMIZER_CONFIG
handle_optimizer_config:
Optimizer release nbr: 0 patch: 1
Optimizer config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Optimizer config Ethos-U version: 1.0.6
Ethos-U config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Ethos-U version: 1.0.6
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke COMMAND_STREAM
handle_command_stream: cmd_stream=703b8110, cms_length 19998
ethosu_release_driver - Driver 30001d20 released
arena_used_bytes : 482348

        #-------------------
        Top prediction for Dog_Breeds
        label: golden retriever
        ID: 208  : Confidence: 12.954923 
        #-------------------

Finished running job: Dog_Breeds
Received inference job response. status=0
Sending inference job
Received inference job. job=30073fc0, name=Bonnie_and_Clyde_Movie_Car
Running inference job: Bonnie_and_Clyde_Movie_Car
ethosu_find_and_reserve_driver - Driver 30001d20 reserved.
ethosu_invoke_v3
ethosu_invoke OPTIMIZER_CONFIG
handle_optimizer_config:
Optimizer release nbr: 0 patch: 1
Optimizer config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Optimizer config Ethos-U version: 1.0.6
Ethos-U config cmd_stream_version: 0 macs_per_cc: 7 shram_size: 24
Ethos-U version: 1.0.6
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke NOP
ethosu_invoke COMMAND_STREAM
handle_command_stream: cmd_stream=703b8110, cms_length 19998
ethosu_release_driver - Driver 30001d20 released
arena_used_bytes : 482348

        #-------------------
        Top prediction for Bonnie_and_Clyde_Movie_Car
        label: pickup, pickup truck
        ID: 718  : Confidence: 9.493684 
        #-------------------

Finished running job: Bonnie_and_Clyde_Movie_Car
Received inference job response. status=0
Application exit code: 0.

EXITTHESIM
Info: /OSCI/SystemC: Simulation stopped by user.
[warning ][main@0][29797177 ns] Simulation stopped by user

--- FVP_MPS3_Corstone_SSE_300 statistics: -------------------------------------
Simulated time                          : 0.512973s
User time                               : 186.070583s
System time                             : 0.318111s
Wall time                               : 186.247928s
Performance index                       : 0.00
FVP_MPS3_Corstone_SSE_300.cpu0          :   0.03 MIPS (     5735052 Inst)
-------------------------------------------------------------------------------
```

## Using your own images

If you want to use your own set of images, check `samples/images.md` for instructions on how to convert and add images.

## Using your own model

You can change the model by using vela and `convert_tflite_to_cpp.sh` script.

Here are instructions for how to change the Mobilenet V2 model from Ethos-U55 with 128 MACs configuration to Ethos-U55 with 256 MACs configuration.


1. Download the Mobilenet V2 model from the Arm Public ML-zoo:
    - https://github.com/ARM-software/ML-zoo/tree/master/models/image_classification/mobilenet_v2_1.0_224/tflite_uint8

1. Use Vela optimizer to optimize the model for Ethos-U55 with 256 MACs
    - If you are not using the docker image, check the main REAME.md for instructions on how to install vela
    ```
    $> vela mobilenet_v2_1.0_224_quantized_1_default_1.tflite --accelerator-config ethos-u55-256
    ```
    The optimized model will be found in `output/mobilenet_v2_1.0_224_quantized_1_default_1_vela.tflite`

1. Convert tflite model to cpp code 
    ```
    $> <repo-root>/sw/convert_scripts/convert_tflite_to_cpp.sh \
        --input output/mobilenet_v2_1.0_224_quantized_1_default_1_vela.tflite \
        --output output/model_vela.cpp 
    ```
    The converted model_vela.cpp is now available to use

1. Copy the new model_vela.cpp to <repo-root>/sw/corstone-300-mobilenet-v2

1. Recompile the application
    ```
    $> cd <repo-root>/sw/corstone-300-mobilenet-v2
    $> make
    ```

1. Run the application
    - You will need to modify the run command by specifying the number of MACs in the configuration.
    See the line `-C ethosu.num_macs=256 \` below.
    ```
    FVP_Corstone_SSE-300_Ethos-U55  \
        --stat \
        -C mps3_board.visualisation.disable-visualisation=1 \
        -C mps3_board.uart0.out_file=- \
        -C mps3_board.telnetterminal0.start_telnet=0 \
        -C mps3_board.uart0.unbuffered_output=1 \
        -C mps3_board.uart0.shutdown_tag="EXITTHESIM" \
        -C cpu0.CFGITCMSZ=14 \
        -C cpu0.CFGDTCMSZ=14 \
        -C ethosu.num_macs=256 \
        -a freertos_mobilenet_v2.elf
    ```

### Other Networks?

As an exercise, you can try to use other networks than Mobilenet V2, but you will need to also make sure that the input data is the correct size and type.
If the input data is images, you can use the Image Conversion scripts shipped with this project, to get images of the correct type and size.

The classification labels may have to be changed depending on the dataset used in training. 

If your input is audio, scripts for this will be available shortly,
for now you can use the ml-embedded-evaluation-kit for these use cases.
