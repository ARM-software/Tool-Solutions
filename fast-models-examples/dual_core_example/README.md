# Dual Core Fast Models Example

This example illustrates how to create an setup a heterogenous Fast Model platform with more than one core for software development and debug. The example has two Fast Model subsystems, one with a Cortex-M0+ core the other with a Cortex-M4. These are subsystems are instantiated into a SystemC platform which also contains private and shared memories and mailbox through which the cores can pass messages. The software example is an adaptation of the "startup" example for each core that is supplied with Arm DS.  The model is supplied as source code with build scripts.  The application is delivered as both pre-built and also as source code.  Scripts to build and run the example are provided.  Thus it can be used out-of-the-box and as the basis for modification to build more complex simulation models and application code.

The example is compatible with Windows and Linux host operating systems. Details of the latest supported platforms can be found in the release notes located here: https://developer.arm.com/tools-and-software/simulation-models/fast-models/release-history.

This example was built and tested with Fast Models 11.11 (released in June 2020).  It will be kept current with the latest version of the tools. To build the example as  described you will need to have installed Fast Models and obtained an evaluation license.

* Fast Models can be downloaded from: https://developer.arm.com/tools-and-software/simulation-models/fast-models

* To obtain an evaluation license for the Cortex-M4 and Cortex-M0+ Fast Models, Contact [license.support@arm.com](mailto:license.support@arm.com) requesting a license for the Cortex-M55 Fast Model.

* To rebuild the software examples, you will also need licenses for Arm Compiler 6 and optionally Arm DS (version 2020.0 or later).

## Organisation of the Example

The example is organised in the following folders

* Build_Cortex-M0Plus - contains the project description for the Cortex-M0+ Fast Model subsystem

* Build_Cortex-M4 - contains the project description for the Cortex-M0+ Fast Model subsystem

* Build_Cortex-M0Plus-M4 - contains the project description for the combined system along with the make files, build, clean and run scripts

* LISA - contains the LISA+ descriptions for the subsystems

* README.md - this file

* Software - has two subfolders, one for each core's bare metal application

* Source - SystemC source files for the top level platform and the Mailbox model 

## Dual Core Fast Models Platform

Folder Contents:

* Makefile / Makefile.common - makefiles for building the platform on Linux hosts
* nMakefile / nMakefile.common - makefiles for building the platform on Windows hosts
* build_linux.sh / build_windows.cmd - build scripts for Linux and Windows (using the makefiles)
* clean_linux.sh / clean_windows.cmd - clean scripts for Linux and Windows (using the makefiles)
* run.cmd / run.sh - run scripts for Windows and Linux

### Platform structue

The platform consists of two Fast Model subsystems and a top level SystemC system. 

The Fast Model systems contain the CPU model (a Cortex-M4 in one, a Cortex-M0+ in the other), a clock generator and ports to connect out to the top level system.  There is a master bus port to bridge the CPU's bus port to the components and the SystemC and a slave signal port to connect a master interrupt port in the SystemC to the interrupt input on the CPU.

The SystemC (mainM0PlusM4.cpp in the Source folder):

* instantiates the two subsystems
* has private memories for each CPU, and a memory shared by both CPUs.  Refer to the .cpp file for the memory map.  The memories are implemented by the amba_pv_memory SystemC model supplied with Fast Models ($MAXCORE_HOME/AMBA-PV/include/models/amba_pv_memory.h).
* has a mailbox memory (Mailbox.cpp/.h in the Source folder) to exchange messages between the CPUs and generate interrupts
* an interconnect constructed through use of amba_pv_decoder SystemC models ($MAXCORE_HOME/AMBA-PV/include/models/amba_pv_decoder.h).  In a virtual prototype we often use such abstract models in lieu of functional models of the interconnect.  amba_pv_decoder.h is a flexible component that implements a N x M interconnect with address filtering.  This platform uses them to split transactions from each CPU to the various memories and merge the inputs to each memory, the memory having a single bus port.

### Building the example

To build the platform, use the build script for the host workstation OS that you are using. The script checks that you have a compatible version of gcc (Linux) or Visual Studio (Windows) installed and then executes the make files with the corresponding libaries.  For info on which hosts and tool chains are supported please refer to the release notes accessible here: https://developer.arm.com/tools-and-software/simulation-models/fast-models/release-history.

Looking at the build process in more detail, there are 2 steps in the flow:

1.  the subsystems are built and SystemC wrappers created.  This step uses the Fast Models "simgen" tool (which in turn uses gcc/VS) to create a shared library and the neccesary headers, etc., to use the subsystems as SystemC modules.

2.  the top level SystemC, additional SystemC components are compiled and linked with the exported Fast Models.  This step uses gcc/VS.

The resulting virtual prototype is the executable "EVS_Cortex-M0Plus-M4.x" (.exe on Windows).

## Example Application Software

A simple application is provided for each processor.  These are based on the "startup" examples distributed with Arm DS.  The memory map (scatter file) has been modified to match that of the memory map in the virtual prototype and some additional code to utilize the inter-processor mailbox has been insterted.

### Folder Contents

In the Software folder the source is divided into two subfolders, one per processor.  The example is delivered with a prebuilt ".axf" enabling the example to be used without the need to compile the application.

In addition each subfolder includes a make file for compiling the example on Linux hosts (requires armclang 6.14 be installed).

We plan to add support for nmake on Windows hosts.  The example can be built using Arm DS following the steps described below.  You will need to go through these steps twice, once for each application

* Open the Arm DS IDE (from a command line, enter armds_ide)
* Open the Project Explorer window
* Right click in the Window, and select "import"
* select C/C++ then "Existing Code as Makefile Project" then "next"
* choose a Project Name (e.g. Cortex-M0Plus, Cortex-M4)
* browse to the location of the "software" directory in the example
* select "Arm Compiler 6" and Finish (if you are prompted to auto-share Git projects, do not do this).  The project will now be imported.
* right click on the new project in the Project Explorer window and select "Build Project".  Progress will be reported in the console window.

The same two objects will be built (startup_Cortex-M4_AC6.axf, startup_Cortex-M4_AC6.dis for the Cortex-M4 and equivalents for the Cortex-MOPlus).  To subsequently rebuild the project (e.g. if you want to experiment with code changes), you will not need go through the import steps again. 

## Running the example 

### Running from the command line ("batch" mode)

In the Build_Cortex-M0Plus-M4 folder the run.cmd/run.sh scripts will run the example.  The command line for running the model is as follows:

* ./EVS_Cortex-M0Plus-M4.x -a Cortex_M4.Core=../Software/startup_Cortex-M4_AC6_sharedmem/startup_Cortex-M4_AC6.axf -a Cortex_M0Plus.Core=../Software/startup_Cortex-M0+_AC6_sharedmem/startup_Cortex-M0+_AC6.axf --stat --cyclelimit 10000000

* -a <file name> specifies the application that will be loaded into the memory at the locations specified in the scatter file for each processor.
* --stat will print some basic run statistics (number of instructions, simulation time) at the end of the run
* --cyclelimit <value> indicates that the simulation should terminate after the given number of instructions.  the application itself is set up to run forever without interruption.

To see the full list of run options available, execute "./EVS_Cortex-M0Plus-M4.x --help".

Other command line switches to try are "--list-params" to get a dump of the parameters in the platform and "--list-instances" to see a dump of the platform structure.

### Running with Model Debugger

Model Debugger is a debug tool supplied with the Fast Models package. When you built the Fast Model in the preceeding steps a debug API was linked in to the executable.  In the command line example used above we did not start the debug server in the platform.  To do this, add "-S" to the command line.

* launch Model Debugger (on Linux, modeldebugger &)
* run the model: ./EVS_Cortex-M0Plus-M4.x -a Cortex_M4.Core=../Software/startup_Cortex-M4_AC6_sharedmem/startup_Cortex-M4_AC6.axf -a Cortex_M0Plus.Core=../Software/startup_Cortex-M0+_AC6_sharedmem/startup_Cortex-M0+_AC6.axf -S
* the model will start and pause waiting for the debugger connection
* in Model Debugger "file" --> "connect to model --> select the model and "connect"
* you will now see a dialogue with all the components in the model.  Model Debugger will provide views into all models, not just the CPUs. The CPUs are selected by default, all other components are deselected.  Proceed with these settings.
* Model Debugger will open various views of the platform for disassembly, registers, memory etc., and provide the typical debugger options of running, stepping by instruction or source line, setting breakpoints etc.  Two windows will be opened, one for each processor.

We don't intend this to be a thorough step-by-step tutorial on Model Debugger, so feel free to experiment with the tool from here on in.  When closing Model Debugger it will not automatically terminate the model, you may need to ctrl-c in the terminal where you started it to do this. 

### Running with Arm DS

Arm DS is software development IDE for that includes a debugger.  You may have already used it in the software build step earlier to build the application.  DS in more full-featured than Model Debugger and we recommend it over the latter when developing and debugging production code.  Model Debugger is simpler to use and its self-discovery of the simulation model contents make it very useful during the platform development as it will automatically pick up any changes.

To run the model with Arm DS:

* launch Arm DS (on Linux, armds_ide &)
* run the model: ./EVS_Cortex-M0Plus-M4.x -a Cortex_M4.Core=../Software/startup_Cortex-M4_AC6_sharedmem/startup_Cortex-M4_AC6.axf -a Cortex_M0Plus.Core=../Software/startup_Cortex-M0+_AC6_sharedmem/startup_Cortex-M0+_AC6.axf -S
* the model will start and pause waiting for the debugger connection

The first time that you connect to a new model in Arm DS you must create a debug configuration. 

* In the DS IDE, open the "Debug Control" window and remove any existing connections.
* click on the "Create a debug connection" link, then select "Model Connection" and "Next"
* give the connection a name, e.g. Cortex-M0-M4 and click next
* clock on Add a new model", leave the model interface ass CADI and click "Next"
* select "Browse for model running on local host" and Next
* select the model, and Finish
* you should now have the "Edit configuration and launch" dialog with your new configuration selected.  Click on Debug.  As this is a dual core system you will need to chose which of the two cores to connect to.

You are now ready to debug with Arm DS.  On subsequent runs, you will be able to reuse the configuration that you created.  after starting Arm DS and running the model as above, right click on the debug configuration that you created in the "Debug Control" window and select "Connect to Target".

## Modifying the example

Once you are comfortable with running the example as provided, you may want to modify it by changing the code, or the platform, or both. Each time you do this you will need to go through the build process again before running the example.

## Contact Us

Have questions, comments, and/or suggestions? Contact [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com).
