# Hello TFLM demo

## Intoduction

This demo shows how to runs a simple network.

The network has no practical use, other than to show the flow, and structure of the demo applicaitons.

## Table of Contents

[[_TOC_]]

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

The result will be an application called `ethosu55-hello-tflm.elf`.

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
    -a ethosu55-hello-tflm.elf
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
ethosu_register_driver: New NPU driver at address 30001250 is registered.
Soft reset NPU
Sending inference job
Received inference job. job=30073e90, name=19_08_01
Running inference job: 19_08_01
arena_used_bytes : 1596
Finished running job: 19_08_01
Received inference job response. status=0
Application exit code: 0.

EXITTHESIM
Info: /OSCI/SystemC: Simulation stopped by user.
[warning ][main@0][1391 ns] Simulation stopped by user

--- FVP_MPS3_Corstone_SSE_300 statistics: -------------------------------------
Simulated time                          : 0.066055s
User time                               : 0.157169s
System time                             : 0.008168s
Wall time                               : 0.165018s
Performance index                       : 0.40
FVP_MPS3_Corstone_SSE_300.cpu0          :   7.08 MIPS (     1171181 Inst)
-------------------------------------------------------------------------------
```

