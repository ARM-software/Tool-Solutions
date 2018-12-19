Running Arm Compute Library examples on a Cortex-R52 Fast Model

## Dependencies

[Arm Fast Models](https://developer.arm.com/products/system-design/fast-models) are required to run the example. Please use the [Fast Models quick start](https://github.com/ARM-software/Tool-Solutions/tree/master/hello-world_fast-models) to get started.

The example hardware system used is in the Fast Models quick start.

Required tools are git and scons and the bare-metal gcc toolchain. The build script will check for them and ask to install or add to the PATH if they are not found. The example has been tested on Ubuntu Linux, but other Linux distributions are possible.

The [GNU-A toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-a/downloads) can be used for the Cortex-R52 development. Please install it and add it to the PATH before running the build script. Use the AArch32 bare-metal target (arm-eabi).

## Usage

Install Fast Models according to the quick start and build the [example Cortex-R52 system](https://github.com/ARM-software/Tool-Solutions/tree/master/hello-world_fast-models/Cortex-R_Armv8-R/system)


Build the Compute Library and example by running the build script:

```bash
./build.sh
```

Once the Compute Library is built, changes to the application can be done using the makefile.

The default application is neon_convolution. Other examples can be compiled by passing the base name of the example to the make step. For example:

```bash
make APP_NAME=neon_sgemm
```

Semihosting is used for the name of the application and any required arguments. This is done by passing a parameter to the to the CPU model using -C.

Run the simulation using isim_system from the quick start with the name of the axf file and the semihosting parameter.

```bash
isim_system -a neon_convolution-Cortex-R52_GCC.axf -C armcortexr52x1ct.cpu0.semihosting-cmd_line="./neon_convolution" 
```

