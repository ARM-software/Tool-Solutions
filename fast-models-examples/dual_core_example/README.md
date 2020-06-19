# Dual Core Example

This example illustrates how to create an setup a heterogenous Fast Model platform with more than one core for software development and debug.  The example has two Fast Model subsystems, one with a Cortex-M0+ core the other with a Cortex-M4. These are subsystems are instantiated into a SystemC platform which also contains private and shared memories and mailbox through which the cores can pass messages. The software example is an adaptation of the "startup" example for each core that is supplied with Arm DS.  The model is supplied as source code with build scripts.  The application is delivered as both pre-built and also as source code.  Scripts to build and run the example are provided.  Thus it can be used out-of-the-box and as the basis for modification to build more complex simulation models and application code.

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


### Building the example


## Example Application Software



### Folder Contents



## Running the example 



### Running from the command line ("batch" mode)



### Running with Model Debugger



### Running with Arm DS



## Modifying the example



## Contact Us

Have questions, comments, and/or suggestions? Contact [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com).
