# Cortex-M55 simple software example

The application software is a hello world bare metal example with additional code to illustrate the Helium capabilities of the Cortex-M55 processor.  Arm Compiler (armclang) 6.14 or above is required to build the software.

The software can be run on a custom Fast Models system as described in the [README](https://github.com/ARM-software/Tool-Solutions/blob/master/fast-models-examples/cortex-m55/README.md) or it can be run on an Arm Ecosystem FVP or an FVP included with Arm Development Studio. Follow the README in the directory above to use a custom Fast Model system. 

The instructions below are to run on the Arm Ecosystem FVP or the FVP included in Arm Deveopment Studio.


## Install the Ecosystem FVP

[Arm Ecosystem FVPs](https://developer.arm.com/tools-and-software/open-source-software/arm-platforms-software/arm-ecosystem-fvps) are available from the Arm Developer website.  Corstone-300 is the one to use.

Download the Windows or Linux version, extract, and run the installer. 

For Linux users the commands are:
```console
curl -L "https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_11.10_44.tgz?revision=c1fd21ac-71f1-408f-88cc-a4c56d561b6b&la=en&hash=27E720C78BAD103BE3B05A26FE4363E3137FC31B" -o FVP_Corstone_SSE_300.tgz && tar xvf FVP_Corstone_SSE_300.tgz  

./FVP_Corstone_SSE-300.sh --i-agree-to-the-contained-eula --no-interactive

```
The FVP is now installed in $HOME/FVP_Corstone_SSE-300/

Windows users can unzip and run the installer manually. 

### Folder Contents

* Makefile / makefile.inc - makefiles to build the application 
* hello.c / startup.c - source code (& object) for the application
* scatter.scat - scatter file used by the linked when building the application

To build the application run make.  The output will be "hello.axf" (the binary object) and "hello.dis", a disassembly listing of the object.

### Running from the command line

To run from the Ecosystem FVP from the command line:

```console
  $HOME/FVP_Corstone_SSE-300/models/Linux64_GCC-6.4/FVP_Corstone_SSE-300 -C fvp_mps2_board.mps2_visualisation.disable-visualisation=1 -C cpu0.INITSVTOR=0x0 -C fvp_mps2_board.DISABLE_GATING=1 -a hello.axf --stat
 ```

You will see the following messages (the Fast Model version may be different according to your installation):

```console
telnetterminal0: Listening for serial connection on port 5000
telnetterminal1: Listening for serial connection on port 5001
telnetterminal2: Listening for serial connection on port 5002

Hello from Cortex-M55!

Sum is: 85344

Info: /OSCI/SystemC: Simulation stopped by user.

--- FVP_MPS2_Corstone_SSE_300 statistics: -------------------------------------
Simulated time                          : 0.108920s
User time                               : 0.032289s
System time                             : 0.002617s
Wall time                               : 0.027701s
Performance index                       : 3.93
FVP_MPS2_Corstone_SSE_300.cpu0          :   0.14 MIPS (        4810 Inst)
-------------------------------------------------------------------------------
```

### Running with Arm Development Studio

The example can be built using Arm DS following the steps described below.  Version 2020.0 (or later) of DS is required for Cortex-M55 support.

* Open the Arm DS IDE (from a command line, enter armds_ide)
* Open the Project Explorer window
* Right click in the Window, and select "import" or click the "Import projects" link
* select C/C++ then "Existing Code as Makefile Project" then "next"
* choose a Project Name (e.g. Cortex-M55)
* browse to the location of the "software" directory in the example
* select "Arm Compiler 6" and Finish (if you are prompted to auto-share Git projects, do not do this).  The project will now be imported.
* right click on the new project in the Project Explorer window and select "Build Project".  Progress will be reported in the console window.

The same two objects will be built (hello.axf, hello.dis). 

To run with Arm DS use the "New Debug Connection" flow to connect to an FVP provided with Arm DS and select the MPS2_Cortex_M55 and load main.axf file. 

Make sure to enter the model parameters in the Connection tab: 
```console
      -C cpu0.FPU=1 -C cpu0.MVE=2 -C cpu0.INITSVTOR=0x0
```

## Contact Us

Have questions, comments, and/or suggestions? Contact [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com).
