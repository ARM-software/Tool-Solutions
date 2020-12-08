____________________________________________________________________________

Building and debugging ASCET-DEVELOPER generated code with Arm Development Studio
____________________________________________________________________________

For more information on this example, please see the enclosed .pdf as well as this article:
xxx (link to blog)

ASCET-DEVELOPER is a model-based development and auto code generation tool for industrial control applications. For more information, including how to get an evaluation see:
        https://www.etas.com/en/products/ascet-developer.php

Arm Development Studio is a comprehensive embedded C/C++ dedicated software development solution specifically for the Arm architecture, including the industry leading Arm Compiler. For more information, including how to get a fully featured 30-day evaluation, see:
        https://developer.arm.com/tools-and-software/embedded/arm-development-studio

The example provided has been written to support the NXP S32K144EVB evaluation board:
        https://www.nxp.com/design/development-boards/automotive-development-platforms/s32k-mcu-platforms/s32k144-evaluation-board:S32K144EVB

using the on-board CMSIS-DAP debug interface
        https://arm-software.github.io/CMSIS_5/DAP/html/index.html
____________________________________________________________________________

ASCET-DEVELOPER setup
____________________________________________________________________________

1)	Unzip the downloaded package from ETAS Download server to your host PC.
2)	Install all of the mentioned packages under folder install 
        •	ASCET-DEVELOPER
        •	Experiment Environment
        •	Virtual Prototype 
3)	Start ASCET and create a new workspace
4)	To simplify path naming, navigate to 
        •	File > Preferences > ESDL > Code Generation
    and change ‘Default Representation Name’ to EVB
____________________________________________________________________________

ASCET-DEVELOPER project import and configuration
____________________________________________________________________________

1)	Download the ASCET.zip file from this repository
2)  Import the ASCET project from the menu system:
        •	File > Import > General > Existing Projects into Workspace
    Select the ASCET.zip file and click Finish

2)	Change the folder into which code is generated match the Arm Development Studio workspace project
        •	Run > Run Configurations
              •	For example "C:\S32K144_ArmIDE_ASCET\S32K144EVB_ARM"
3)	Click ‘Apply’, and then ‘Run’. The code will now be auto-generated into your Development Studio project, within the ./src folder

For further instructions on how to write an ASCET Program and other functionality, open the user help (Menu Help > Help Contents).
Navigate to chapter ASCET-DEVELOPER User Guide > Getting Started and do the Tutorial (Highly recommended)
____________________________________________________________________________

Arm Development Studio setup and building project
____________________________________________________________________________

1)	Download Arm_DS.zip file from this repository.
2a) Either simply unzip this file, creating S32K144_ArmIDE_ASCET folder, and in the Development Studio IDE, navigate to
        •	File > Switch Workspace
    and select above S32K144_ArmIDE_ASCET folder.
2b) Alternatively import projects (InterpolationS32 and S32K144EVB_ARM) into another workspace via
        •	File > Import >  General > Existing Projects into Workspace
3)	Clean and rebuild the S32K144EVB_ARM project if desired. InterpolationS32 is a library used by this example (note rebuilding library may take some time).

For more information on using Development Studio IDE functionality, see:
https://developer.arm.com/documentation/101470/latest/Working-with-projects
____________________________________________________________________________

Development board setup
____________________________________________________________________________

1)	Reflash EVB Debug processor to CMSIS-DAP as described in section 9 (page 8) of the below document:
        • https://www.keil.com/appnotes/files/apnt_299_v1.2.pdf
2)	Move jumper J107 to connect pins 1 and 2 (instead of 2 and 3)
3)  Connect the USB cable from your PC to the board
4)	Provide a 12V supply on the IN 12V socket (required for CAN interface)
____________________________________________________________________________

Debug setup and debugging the example project
____________________________________________________________________________

1)	Open the CMSIS Pack Manager perspective, and locate and install Keil.S32_SDK_DFP.
    This provides necessary information to connect to and debug the evaluation board.
2)	Double-click on debug configuration (S32K144EVB.launch) and browse for the CMSIS-DAP connection to the board.
3)	Click debug to connect to target, and download the built image.
    Subsequent connections can simply be done directly from the Debug Control pane.
4)  Click continue to run the code on the target.

For more information on using Arm Debugger, see the Development Studio User Guide and other documentation:
https://developer.arm.com/tools-and-software/embedded/arm-development-studio/learn/docs
