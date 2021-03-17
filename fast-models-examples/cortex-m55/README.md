# Cortex-M55 Example

This example illustrates the use of the Cortex-M55 Fast Model for software development and debug.  There is a simple Fast Models platform that simulates a Cortex-M55 processor and memory along with an accompanying software application.  Both the model and the application are delivered pre-built and also as source code.  Scripts to build and run the example are provided.  Thus it can be used out-of-the-box and as the basis for modification to build more complex simulation models and application code.

The example is compatible with Windows and Linux host operating systems. Details of the latest supported platforms can be found in the release notes located here: https://developer.arm.com/tools-and-software/simulation-models/fast-models/release-history.

This example was built and tested with Fast Models 11.10 (released in March 2020).  It will be kept current with the latest version of the tools. To build the example as  described you will need to have installed Fast Models and obtained an evaluation license.

* Fast Models can be downloaded from: https://developer.arm.com/tools-and-software/simulation-models/fast-models

* To obtain an evaluation license for the Cortex-M55 Fast Model, visit [Arm support](https://developer.arm.com/support) and request a license for the Cortex-M55 Fast Model.  You will also need licenses for Arm Compiler 6 and optionally Arm DS (version 2020.0 or later).

## Organisation of the Example

The example is split into two sub-folders:

* software contains the example application.  This is supplied as source code with support for building the code. The software directory also has a README with instructions to run on the Arm Ecosystem FVP and the FVP included with Arm Development Studio.
* system contains the Fast Models based platform.  This is supplied with build scripts to compile the model for execution.

## Cortex-A55 Fast Models Platform

Folder Contents:

* Makefile /  Makefile.common - Makefiles for building the platform on Linux platforms
* nMakefile / nMakefile.common - Makefiles for building the platform on Linux platforms
* build_linux.sh / build_windows.cmd - Build scripts for Linux and Windows 
* clean_linux.sh / clean_windows.cmd - Clean scripts for Linux and Windows
* m55.lisa - LISA+ source code for the top level of the Fast Models Cortex-M55 subsystem
* m55.sgcanvas / m55.sgproj- configuration information for building the Fast Models platform and displaying in System Canvas
* main.cpp / trickbox.cpp / trickbox.h - SystemC files for the Fast Models platform and utilities

### Building the example

Before you can run the example you must build the Fast Model. The platform is supported on Windows (7 and 10) and Linux (RHEL and Ubuntu).  On Windows an installation of Visual Studio 2015 or 2017 is required to build the platform.  On Linux gcc is used to build the platform.  The latest supported platforms and tool chains can be found in the release notes located here: https://developer.arm.com/tools-and-software/simulation-models/fast-models/release-history.

The build scripts, build_linux.sh and build_windows.cmd will build the platform.  They check that a supported tool chain is available and in the PATH variable before continuing.  The build runs in two steps:

1. this step runs the Fast Models "simgen" utility.  This compiles the m55.lisa code into an Exported Virtual Subsystem (or EVS) using gcc or Visual Studio.  This is a Fast Model with a SystemC wrapper with all the neccessary libraries and headers for inclusion into a SystemC simulation.

2. this step compiles the SystemC files using gcc or Visual Studio linking the previously compiled Fast Models and the Accellera SystemC simulation kernel.

Upon completion an excutuable called Cortex-M55.x (Linux) or Cortex-M55.exe (Windows) will be created.

## Example Application Software

The application software is a hello world bare metal example with additional code to illustrate the Helium capabilities of the Cortex-M55 processor.  Arm Compiler (armclang) 6.14 is required to build the software.

### Folder Contents

* Makefile / makefile.inc - makefiles to build the application on Linux hosts
* hello.c / startup.c - source code (& object) for the application
* scatter.scat - scatter file used by the linked when building the application

To build the application on Linux hosts, use make.  The output will be "hello.axf" (the binary object) and "hello.dis", a disassembly listing of the object.

We plan to add support for nmake on Windows hosts.  The example can be built using Arm DS following the steps described below.  Version 2020.0 (or later) of DS is required for Cortex-M55 support.

* Open the Arm DS IDE (from a command line, enter armds_ide)
* Open the Project Explorer window
* Right click in the Window, and select "import"
* select C/C++ then "Existing Code as Makefile Project" then "next"
* choose a Project Name (e.g. Cortex-M55)
* browse to the location of the "software" directory in the example
* select "Arm Compiler 6" and Finish (if you are prompted to auto-share Git projects, do not do this).  The project will now be imported.
* right click on the new project in the Project Explorer window and select "Build Project".  Progress will be reported in the console window.

The same two objects will be built (hello.axf, hello.dis).  To subsequently rebuild the project (e.g. if you want to experiment with code changes), you will not need go through the import steps again. 

## Running the example 

With the platform and the application now built you can run the simulation. There are several ways to do this. We will describe some of them here.

### Running from the command line ("batch" mode)

To run from the command line, follow these steps.  From the "system" folder, enter

* ./Cortex-M55.x -a ../software/hello.axf --stat

You will see the following messages (the Fast Model version may be different according to your installation):

```console
Fast Models [11.10.42 (May 14 2020)]
Copyright 2000-2020 ARM Limited.
All Rights Reserved.


Hello from Cortex-M55!

Sum is: 85344

Info: /OSCI/SystemC: Simulation stopped by user.

--- m55 statistics: -----------------------------------------------------------
Simulated time                          : 0.000048s
User time                               : 0.008743s
System time                             : 0.002987s
Wall time                               : 0.014826s
Performance index                       : 0.00
m55.armcortexm55ct                      :   0.41 MIPS (        4781 Inst)
-------------------------------------------------------------------------------
```

This shows that the program executed correctly and gives some statistics on the run.

### Running with Model Debugger

Model Debugger is a debug tool supplied with the Fast Models package. When you built the Fast Model in the preceeding steps a debug API was linked in to the executable.  In the command line example we did not start the debug server in the platform.  To do this, add "-S" to the command line.

* launch Model Debugger (on Linux, modeldebugger &)
* run the model: ./Cortex-M55.x -a ../software/hello.axf --stat -S
* the model will start and pause waiting for the debugger connection
* in Model Debugger "file" --> "connect to model --> select the model and "connect"
* you will now see a dialogue with all the components in the model.  Model Debugger will provide views into all models, not just the CPU. The CPU is selected by default, all other components are deselected.  Proceed with these settings.
* Model Debugger will open various views of the platform for disassembly, registers, memory etc., and provide the typical debugger options of running, stepping by instruction or source line, setting breakpoints etc.

We don't intend this to be a thorough step-by-step tutorial on Model Debugger, so feel free to experiment with the tool from here on in.  When closing Model Debugger it will not automatically terminate the model, you may need to ctrl-c in the terminal where you started it to do this. 

### Running with Arm DS

Arm DS is software development IDE for that includes a debugger.  You may have already used it in the software build step earlier to build the application.  DS in more full-featured than Model Debugger and we recommend it over the latter when developing and debugging production code.  Model Debugger is simpler to use and its self-discovery of the simulation model contents make it very useful during the platform development as it will automatically pick up any changes.

To run the model with Arm DS:

* launch Arm DS (on Linux, armds_ide &)
* run the model: ./Cortex-M55.x -a ../software/hello.axf --stat -S
* the model will start and pause waiting for the debugger connection

The first time that you connect to a new model in Arm DS you must create a debug configuration. 

* In the DS IDE, open the "Debug Control" window and remove any existing connections.
* click on the "Create a debug connection" link, then select "Model Connection" and "Next"
* give the connection a name, e.g. Cortex-M55 and click next
* clock on Add a new model", leave the model interface ass CADI and click "Next"
* select "Browse for model running on local host" and Next
* select the model, and Finish
* you should now have the "Edit configuration and launch" dialog with your new configuration selected.  Click on Debug.

You are now ready to debug with Arm DS.  On subsequent runs, you will be able to reuse the configuration that you created.  after starting Arm DS and running the model as above, right click on the debug configuration that you created in the "Debug Control" window and select "Connect to Target".

## Modifying the example

Once you are comfortable with running the example as provided, you may want to modify it by changing the code, or the platform, or both. Each time you do this you will need to go through the build process again before running the example.

## Contact Us

Have questions, comments, and/or suggestions? Contact [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com).
