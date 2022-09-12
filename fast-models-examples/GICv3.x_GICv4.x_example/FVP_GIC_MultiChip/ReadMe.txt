Caution
=======
We took this frmaework from PEG to give tutorial on GIC programming on top
of FVP Base platform, and FastModel team tweaked it to test GIC Multichip
functions, so most details below is somewhat a mixture of original PEG
tutorial and Multichip operation testing.
This is under severe development, so please contact Jun-Kyoung Kim or
Rida Jichi to get more details or correct information.


AArch64 Generic Timer Example
=============================

Introduction
============
This example demostrates the use of the Generic Timer in a baremetal environment.


Notice
=======
Copyright (C) Arm Limited, 2019 All rights reserved.

The example code is provided to you as an aid to learning when working 
with Arm-based technology, including but not limited to programming tutorials. 
Arm hereby grants to you, subject to the terms and conditions of this Licence, 
a non-exclusive, non-transferable, non-sub-licensable, free-of-charge licence, 
to use and copy the Software solely for the purpose of demonstration and 
evaluation.

You accept that the Software has not been tested by Arm therefore the Software 
is provided �as is�, without warranty of any kind, express or implied. In no 
event shall the authors or copyright holders be liable for any claim, damages 
or other liability, whether in action or contract, tort or otherwise, arising 
from, out of or in connection with the Software or the use of Software.


Requirements
============
* DS-5 Ultimate Edition (5.29 or later) or Arm Development Studio
* AEMv8 BasePlatform FVP


File list
=========
 <root>
  |-> headers
  |   |-> generic_timer.h
  |   |-> gicv3_basic.h
  |   |-> gicv3_lpis.h
  |   |-> gicv3_registers.h
  |   |-> gicv4_virt.h
  |   |-> system_counter.h
  |
  |-> src
  |   |-> el3_vectors.s      Minimal vector table
  |   |-> generic_timer.s    Helper functions for Generic Timer
  |   |-> gicv3_basic.c      Helper functions for GICv3.1
  |   |-> gicv3_lpis.c       Helper functions for GICv3.1 physical LPIs
  |   |-> gicv4_virt.c       Helper functions for GICv4.1 virtualization
  |   |-> mc_config_test.c   Example showing multichip configuration and changing default chip
  |   |-> main_lpis.c        Example showing usage of physical LPIs.
  |   |-> main_lpis.c        Example showing usage of GICv4.1 virtual LPIs.
  |   |-> secondary_vlpis.s  Example showing usage of GICv4.1 virtual LPIs.
  |   |-> startup.s          Minimal reset handler.
  |   |-> startup_vlpis.s    Minimal reset handler, used by virtual LPI example.
  |   |-> system_counter.s   Helper functions for System Counter
  |
  |-> ReadMe.txt             This file
  |-> scatter.txt            Memory layout for linker


Description
===========


Building the example from the command line
==========================================
To build the example:
- Open a DS-5 or Arm Developer Studio command prompt, then navigate to the location of the example

To mount ARMCLANG compiler, run:
    eval `setup_wh_comp ARMCC:TestableTools:6.3:checking=none,regime=rel`


For GICv3.1:
    - Run "make"
    
For GICv4.1:
    - Run "make GIC=GICV4"       to build PPI, SPI and pLPI examples.
    - Run "make GIC=GICV4 gicv4" to vLPI examples.


Note:
When a GIC implements GICv3.x, the Redistributors occupy 128K of address space.  When GICv4.x is implemented, they occupy 256K.  The example requires the Redistributor size at build time, which is why it is passed as an argeument to make.

Explanation of the multichip GIC tests
======================================

mc_config.axf     : Tests the configuring of the multiple GICs to operate in a multichip configuration.
                    This includes the following functionalities:
                    * Connecting to new remote chips (bringing chips online)
                    * Disconnecting connected remote chips (setting a chip offline)
                    * Switching the Routing Table (RT) owner
                    The test checks that the multichip registers (Routing Table) in the GICs are coherent.

mc_lpi_cmd.axf    : Tests the ITS physical-LPI commands in a multichip configuration.
                    Checks that affected LPIs are moved cross-chip to, and processed at, the right destination CPU.
                    The tested physical-LPI commands are:
                    * MOVI (only scenarios C2 and C4)


Explanation of model paramaters
===============================
These examples are intended to run on the FVP Base Platform model (FVP_Base_AEMv8A-AEMv8A).
This model takes a number of parameters to configure how the GIC appears to software.
Unfortunately in a number of cases we need non-default values.
This section describes the parameters used for the different examples.

-C cluster0.gicv3.extended-interrupt-range-support=1
Controls whether the PE supports the extended ranges

-C gic_distributor.extended-ppi-count=<n>
Controls how many (if any) GICv3.1 extended PPIs are available, default 0.  The image_basic example requires this to be set to 32.

gic_distributor.extended-spi-count=<n>
Controls how many (if any) GICv3.1 extended SPIs are available, default 0.  The image_basic example requires this to be set to 32.

-C gic_distributor.ITS-count=<n>
Controls how many (if any) ITSs are present, default 0. Most of these examples require it to be set to 1.

-C gic_distributor.ITS-use-physical-target-addresses=<n>
Controls the value of GITS_TYPER.PTA, default 1.  Most of these examples requires it to be set to 0.

-C gic_distributor.virtual-lpi-support=<bool>
Whether the GIC supports GICv4.x, default FALSE.
When TRUE, has-gicv4.1 controls whether 4.0 or 4.1 is implemented.

-C has-gicv4.1=<bool>
Whether the GIC supports GICv4.1, default FALSE.  The GICv4.1 examples require this to be set to TRUE.

Note: The spacing of Redistributors changes when GICv4.1 is implemented, which is why the make command changes.

-C gic_distributor.GITS_BASER<x>-type=<n>
The type of table for each GITS_BASER<n> register.  This example expects:
GITS_BASER0 = 1
GITS_BASER1 = 4
GITS_BASER2 = 2 (only when "has-gicv4.1=1")

-C gic_distributor.ITS-vmovp-bit=<bool>
Controls the value of GITS_TYPER.VMOVP, default 0.  GICv4.1 examples require 1.

-C gic_distributor.common-lpi-configuration=2 
-C gic_distributor.ITS-shared-vPE-table=2

Collectively control the ITS's CommonLPIAff behaviour.
GICv4.1 examples require them both to be set to 2.


Running the example on GICv3.x:
===============================
- Open a command prompt, then navigate to the location of Base Platform FVP executeable
- Run:

  FVP_Base_AEMv8A-AEMv8A -C cluster0.NUM_CORES=1 -C cluster0.gicv3.extended-interrupt-range-support=1 -C cluster1.NUM_CORES=0 -C gic_distributor.GITS_BASER0-type=1 -C gic_distributor.GITS_BASER1-type=4 -C bp.secure_memory=0 -C gic_distributor.ITS-count=1 -C gic_distributor.ITS-use-physical-target-addresses=0 -C gic_distributor.GITS_BASER6-type=0 -C gic_distributor.extended-spi-count=32 -C gic_distributor.extended-ppi-count=32 --application=<path_to_example>


Running the example on GICv4.1:
===============================
- Open a command prompt, then navigate to the location of Base Platform FVP executeable
- Run:

FVP_Base_AEMv8A-AEMv8A -C cluster0.NUM_CORES=2 -C cluster0.gicv3.extended-interrupt-range-support=1 -C cluster1.NUM_CORES=0 -C gic_distributor.GITS_BASER0-type=1 -C gic_distributor.GITS_BASER1-type=4 -C gic_distributor.GITS_BASER2-type=2 -C bp.secure_memory=0 -C gic_distributor.ITS-count=1 -C gic_distributor.ITS-use-physical-target-addresses=0 -C gic_distributor.GITS_BASER6-type=0 -C has-gicv4.1=1 -C gic_distributor.virtual-lpi-support=1 -C gic_distributor.reg-base-per-redistributor=0.0.0.0=0x2f100000,0.0.0.1=0x2f140000,0.0.0.2=0x2f180000,0.0.0.3=0x2f1C0000,0.0.1.0=0x2f200000,0.0.1.1=0x2f240000,0.0.1.2=0x2f280000,0.0.1.3=0x2f280000 -C gic_distributor.common-lpi-configuration=2 -C gic_distributor.ITS-shared-vPE-table=2 -C gic_distributor.ITS-vmovp-bit=1 -C gic_distributor.has_VPENDBASER-dirty-flag-on-load=1 -C gic_distributor.extended-ppi-count=32


-C TRACE.TarmacTrace.trace-file=trace.txt -C TRACE.TarmacTrace.trace_gicv3_its=1 -C TRACE.TarmacTrace.trace_gicv3_comms=0x4 -C TRACE.TarmacTrace.trace_gicv3_reads=1

Running the example on MultiGIC (multichip operation):
======================================================
- Open a command prompt, then navigate to the location of Base Platform FVP executeable
- Run:

FVP_Base_AEMv8A-AEMv8A-MultiGIC -T 120 -C gic_iri.print-memory-map=1 -C cluster0.NUM_CORES=2 -C cluster0.gicv3.extended-interrupt-range-support=1 -C cluster1.NUM_CORES=0 -C bp.secure_memory=0 -C gic_iri.ITS-count=1 -C gic_iri.extended-ppi-count=32 --application=<path to axf>

Note that the FVP Base AEMv8A-AEMv8A MultiGIC platform uses Clayton, which has multichip operation enabled and mandates
the value of GITS_TYPER.PTA (set from the parameter ITS-use-physical-target-addresses) to be set to 0. This aligns
with the expectation of most of these tests.

#
# THE BELOW STILL NEEDS RE-WRITING
#

Building and running the example using DS-5
===========================================
* In DS-5, go to File -> Import.
* Select General -> "Existing Projects into Workspace", 
* Navigate to and select the generic_timer example, then click Finish.
* In the C/C++ perspective, select the "generic_timer" project and then Project -> "Build Project".
* Once the project has built, right-click generic_timer_example.launch and "Debug as"



Building and running the example using Arm Development Studio
=============================================================
* In Arm DS, go to File -> Import.
* Select General -> "Existing Projects into Workspace",
* Navigate to and select the generic_timer_ArmDS example, then click Finish.
* In the Development Studio perspective, select the "generic_timer_ArmDS" project and then Project -> "Build Project".
* Once the project has built, right-click generic_timer_example.launch and "Debug as" -> generic_timer_example
