## Cortex-M33 AMBA-PV TLM-2.0 Subsystem using Fast Models

Detailed instructions on how to assemble, build and run this subsystem are available
in this [blog](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/cortex-m33-systemc-subsystem-using-fast-models) post.

## Generate the Cortex-M33 Subsystem

1. To export the Cortex-M33 subsystem, change directory to "system/subsystem" and open "sgcanvas".
2. In System Canvas, open the project by clicking File then Load Project and open "MyTopComponent.sgproj". This loads the assembled subsystem in System Canvas.
3. Go to Project then Project Settings menu and select "Linux64-Release-GCC-6.4" configuration from the "Configuration" drop down.
4. Then Select "SystemC component" as the Target from Targets window. De-select all other options. Then press "Apply" and "Ok" to continue.
5. Final, step is to press the "Build" button from the Ribbon menu. This should make the build process to start and complete successfully.

## Complete Platform generation

1. Change directory to "system/systemc-plt", check that the PLT\_EXPORT in Makefile is correctly pointing to "system/subsystem/Linux64-Release-GCC-6.4" directory.
2. Then, run "make" to build the platform

## Compile the RTX App

1. Change directory to "software". Ensure that you have armclang in your path.
2. Download CMSIS\_5 repo from [this link](https://github.com/ARM-software/CMSIS_5). Update CMSIS\_HOME to point to CMSIS\_5 diretory of CMSIS repo.
2. Finally, Run "make" to compile the RTX App. On successful compiltion, "test.axf" is built in the current directory.

## Executing the platform with RTX App

1. Change directory to "system/systemc-plt" and execute the platform binary as follows:
```bash
$ ./plt -a ../../software/test.axf
```

