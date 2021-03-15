# Person Detection demo

## Intoduction

This demo detects weither there is a person in an image or not.

The input image is grayscale (single channel) with a resolution of 96x96 pixels.

## Table of Contents

[[_TOC_]]

## Resources

Here is a list of the resources used in this application

### Model
The model is a Mobilenet V1 based model, from tensorflow lite micro examples. 
It can be accessed and recreated from the link below

* https://github.com/tensorflow/tensorflow/tree/master/tensorflow/lite/micro/examples/person_detection

### Images

The sample images used in this project are under the CC license
The originals can be found here:
* https://commons.wikimedia.org/wiki/File:Person-tree.jpg
* https://www.piqsels.com/en/public-domain-photo-ofjja
* https://commons.wikimedia.org/wiki/File:POV-cat.jpg
* https://commons.wikimedia.org/wiki/File:JP-Kyoto-kimono.jpg


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

The result will be an application called `ethosu55-person-detection.elf`.

## Run apllication with Fixed Virtual Platform (FVP)

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
    -a ethosu55-person-detection.elf
```

You will see some info messages from the npu, along with the result from the inferece.

The application will look something like this in a successful run:

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
ethosu_register_driver: New NPU driver at address 30000d60 is registered.
Soft reset NPU
Sending inference job
Received inference job. job=30073ed8, name=tree
Running inference job: tree
ethosu_find_and_reserve_driver - Driver 30000d60 reserved.
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
handle_command_stream: cmd_stream=70035420, cms_length 2545
ethosu_release_driver - Driver 30000d60 released
arena_used_bytes : 83340

#-----------------------------
  No Person Confidence = 2.213933 | Person Confidence = -1.237198
  Detected NO PERSON in the input image
  Confidence = 2.213933
#-----------------------------

Finished running job: tree
Received inference job response. status=0
Sending inference job
Received inference job. job=30073ed8, name=person_male_man_men
Running inference job: person_male_man_men
ethosu_find_and_reserve_driver - Driver 30000d60 reserved.
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
handle_command_stream: cmd_stream=70035420, cms_length 2545
ethosu_release_driver - Driver 30000d60 released
arena_used_bytes : 83340

#-----------------------------
  No Person Confidence = -0.862783 | Person Confidence = 2.197654
  Detected A PERSON in the input image
  Confidence = 2.197654
#-----------------------------

Finished running job: person_male_man_men
Received inference job response. status=0
Application exit code: 0.

EXITTHESIM
Info: /OSCI/SystemC: Simulation stopped by user.
[warning ][main@0][415697 ns] Simulation stopped by user

--- FVP_MPS3_Corstone_SSE_300 statistics: -------------------------------------
Simulated time                          : 0.334961s
User time                               : 12.785935s
System time                             : 0.031687s
Wall time                               : 12.758418s
Performance index                       : 0.03
FVP_MPS3_Corstone_SSE_300.cpu0          :   0.42 MIPS (     5334307 Inst)
-------------------------------------------------------------------------------
```

