## Cortex-M33 AMBA-PV TLM-2.0 Subsystem using Fast Models

Detailed instructions on how to assemble, build and run this subsystem are available
in this [blog](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/cortex-m33-systemc-subsystem-using-fast-models) post.

For details on Fast Models, including pre-requisites for the the host workstation, please refer to the release notes available on the [Arm Developer](https://developer.arm.com/tools-and-software/simulation-models/fast-models/release-history) website.

## Building the Fast Model Platform using the build scripts

For convenience we have provided scripts to build the Fast Models platforms for both Linux and Windows host platforms.  To use these:

1. Change directory to system/systemc_plt
2. To build the platform for Linux hosts, run the build_linux.sh script. Fast Models supports several versions of the gcc tool chain for building the platform.  To select which version of gcc you want to use edit the build_linux.sh script uncommenting the appropriate make command.  gcc 7.3 is initially enabled when you install the example.
3. To build the platform for Windows hosts, run the build_windows.cmd script. Fast Models supports Visual Studio 2015 and Visual Studio for building the platform, you will need to have access to one or other of these. To select which version of Visual Studio you want to use edit the build_windows.cmd uncommenting the appropriate nmake command. Visual Studio 2017 is enabled by default.
4. clean_linux.sh and clean_windows.cmd scripts are provided to clean the package from previous builds.

The build scripts first call the Fast Models "simgen" command to generate the Cortex-M33 subsystem and then either gcc or Visual Studio to compile the SystemC with the exported Fast Model subsystem. As an alternative to using the scripts you run each step individually following the instructions below.

## Generate the Cortex-M33 Subsystem (if not using the "build" script)

1. To export the Cortex-M33 subsystem, change directory to "system/subsystem" and open "sgcanvas" (System Canvas).
2. In System Canvas, open the project by clicking File then Load Project and open "MyTopComponent.sgproj". This loads the assembled subsystem in System Canvas.
3. Go to Project then Project Settings menu and select the toolchain that you want to use through  the "Configuration" drop down. If you are running on a Linux host you will see the gcc variants that Fast Models supports in the dropdown, on Windows you will see the supported Visual Studio variants.
4. Then Select "SystemC component" as the Target from Targets window. De-select all other options. Then press "Apply" and "Ok" to continue.
5. Final, step is to press the "Build" button from the Ribbon menu. This will start the build process and complete successfully.

## Compile the SystemC platform (if not using the "build" script)

1. Change directory to "system/systemc-plt" folder.
2. On a Linux host, run "make rel_gccNN_64" to build the platform, where NN is one of the supported gcc variants.  The options are currently "49", "64" or "73".
3. On a Windows host, run "nmake /nologo /f nMakefile rel_vs141_64" to build the platform with Visual Studio 2017 or "nmake /nologo /f nMakefile rel_vs14_64" to build with Visual Studio 2017.

## Compile the RTX App

1. Change directory to "software". Ensure that you have armclang in your path.
2. Download CMSIS\_5 repo from [this link](https://github.com/ARM-software/CMSIS_5). Update CMSIS\_HOME to point to CMSIS\_5 diretory of CMSIS repo.
2. Finally, Run "make" to compile the RTX App. On successful compiltion, "test.axf" is built in the current directory.

## Executing the platform with RTX App

1. Change directory to "system/systemc-plt" and execute the platform binary as follows:
```bash
$ ./plt -a ../../software/test.axf
```

