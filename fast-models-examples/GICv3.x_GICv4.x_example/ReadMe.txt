AArch64 Generic Interrupt Controller (v3/v4) Example
====================================================

Introduction
============
This example demostrates the use of the Generic Interrupt Controller (GIC) in a baremetal environment.


Notice
=======
Copyright (C) Arm Limited, 2019-2021 All rights reserved.

The example code is provided to you as an aid to learning when working
with Arm-based technology, including but not limited to programming tutorials.
Arm hereby grants to you, subject to the terms and conditions of this Licence,
a non-exclusive, non-transferable, non-sub-licensable, free-of-charge licence,
to use and copy the Software solely for the purpose of demonstration and
evaluation.

You accept that the Software has not been tested by Arm therefore the Software
is provided 'as is', without warranty of any kind, express or implied. In no
event shall the authors or copyright holders be liable for any claim, damages
or other liability, whether in action or contract, tort or otherwise, arising
from, out of or in connection with the Software or the use of Software.


Requirements
============
* AEMvA-AEMvA BasePlatform FVP


File list
=========
 <root>
  |-> headers
  |   |-> generic_timer.h
  |   |-> gicv3_basic.h
  |   |-> gicv3_lpi.h
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
  |   |-> main_basic.c       Example showing usage of SPIs and PPIs.
  |   |-> main_gicv31.c      Example showing usage of GICv3.1 Extended PPI and SPI rangess.
  |   |-> main_lpi.c         Example showing usage of physical LPIs.
  |   |-> main_vlpi.c        Example showing usage of GICv4.1 virtual LPIs.
  |   |-> main_vsgi.c        Example showing usage of GICv4.1 virtual SGIs.
  |   |-> secondary_virt.s   Boot code for secondary core, used by the GICv4.1 example.
  |   |-> startup.s          Minimal reset handler.
  |   |-> startup_virt.s     Minimal reset handler, used by the GICv4.1 example.
  |   |-> system_counter.s   Helper functions for System Counter
  |
  |-> Makefile
  |-> ReadMe.txt             This file
  |-> scatter.txt            Memory layout for linker


Description
===========
The package includes a number of small example programs, each demonstrating a different aspect of using the GIC.

These examples work with GICv3.x and GICv4.x:

image_basic
This example shows the basic set up of a GICv3/4 interrupt controller, including the PPI and SPI interrupt types.

image_lpi
This example shows the setup and use of physical LPIs and the ITS.


These examples require GICv3.1:

image_gicv31
This examples shows the use of the GICv3.1 extended PPI and SPI ranges.


These examples require GICv4.1:

image_vlpi
This example shows the setup and use of GICv4.1 virtual LPIs.

image_vsgi
This example shows the setup and use of GICv4.1 virtual SGIs.



Building the example from the command line
==========================================

The make command depends on the version of the GIC architecture implemented.

For GICv3.x:
    - Run "make"

For GICv4.1:
    - Run "make GIC=GICV4"       to build PPI, SPI and physical LPI examples.
    - Run "make GIC=GICV4 gicv4" to vLPI and vSGI examples.


Optionally, adding "DEBUG=TRUE" results in additional logging messages being printed.

Note:
When a GIC implements GICv3.x, the Redistributors occupy 128K of address space.
When GICv4.x is implemented, they occupy 256K.
The example requires the Redistributor size at build time,
which is why the GIC version is passed as an argeument to make.


Explanation of model paramaters
===============================
These examples are intended to run on the FVP Base Platform model (FVP_Base_AEMvA-AEMvA).
This model takes a number of parameters to configure how the GIC appears to software.
Some of the examples require non-default values, this section describes the parameters used for the different examples.

-C cluster0.gicv3.extended-interrupt-range-support=1
Controls whether the PE supports the GICv3.1 extended range, default 0.  the image_gicv31 examples requires this to be set to 1.


-C gic_distributor.extended-ppi-count=<n>
Controls how many (if any) GICv3.1 extended PPIs are available, default 0.  The image_gicv31 example requires this to be set to 32.


-C gic_distributor.extended-spi-count=<n>
Controls how many (if any) GICv3.1 extended SPIs are available, default 0.  The image_gicv31 example requires this to be set to 32.


-C gic_distributor.ITS-count=<n>
Controls how many (if any) ITSs are present, default 0. Most of the examples require it to be set to 1.


-C gic_distributor.ITS-use-physical-target-addresses=<n>
Controls the value of GITS_TYPER.PTA, default 1.  Most of the examples requires it to be set to 0.


-C gic_distributor.virtual-lpi-support=<bool>
Whether the GIC supports GICv4.x, default FALSE.  The GICv4.1 examples require it to be set to TRUE.


-C has-gicv4.1=<bool>
Whether the GIC supports GICv4.1, default FALSE.  The GICv4.1 examples require this to be set to TRUE.


-C gic_distributor.GITS_BASER<x>-type=<n>
The type of table for each GITS_BASER<n> register.  Most of the examples require to be set to:
GITS_BASER0 = 1
GITS_BASER1 = 4
GITS_BASER2 = 2 (GICv4.1 examples only)
as this is Arm's recommended allocations for GITS_BASER<n> [^1]


-C gic_distributor.ITS-vmovp-bit=<bool>
Controls the value of GITS_TYPER.VMOVP, default 0.  GICv4.1 examples require 1.


-C gic_distributor.common-lpi-configuration=2
-C gic_distributor.ITS-shared-vPE-table=2

Collectively control the ITS's CommonLPIAff behaviour.
GICv4.1 examples require them both to be set to 2.


Running the example on GICv3.0:
===============================
The image_basic and image_lpi examples are compatible with GICv3.0.

- Open a command prompt, then navigate to the location of Base Platform FVP executeable
- Run:

  FVP_Base_AEMvA-AEMvA -C cluster0.NUM_CORES=1 -C cluster1.NUM_CORES=0 -C gic_distributor.GITS_BASER0-type=1 -C gic_distributor.GITS_BASER1-type=4 -C bp.secure_memory=0 -C gic_distributor.ITS-count=1 -C gic_distributor.ITS-use-physical-target-addresses=0 -C gic_distributor.GITS_BASER6-type=0 --application=<path_to_example>

Alternatively, replace all the -C options with

  -f <path_to_example_dir>/gicv3_all.params


Running the example on GICv4.1:
===============================
All the examples are compatible with GICv4.1.

- Open a command prompt, then navigate to the location of Base Platform FVP executeable
- Run:

FVP_Base_AEMvA-AEMvA -C cluster0.NUM_CORES=2 -C cluster1.NUM_CORES=0 -C bp.secure_memory=0 -C gic_distributor.ITS-count=1 -C gic_distributor.ITS-use-physical-target-addresses=0 -C gic_distributor.GITS_BASER0-type=1 -C gic_distributor.GITS_BASER1-type=4 -C gic_distributor.GITS_BASER2-type=2 -C gic_distributor.GITS_BASER6-type=0 -C has-gicv4.1=1 -C gic_distributor.virtual-lpi-support=1 -C gic_distributor.reg-base-per-redistributor=0.0.0.0=0x2f100000,0.0.0.1=0x2f140000,0.0.0.2=0x2f180000,0.0.0.3=0x2f1C0000,0.0.1.0=0x2f200000,0.0.1.1=0x2f240000,0.0.1.2=0x2f280000,0.0.1.3=0x2f280000 -C gic_distributor.common-lpi-configuration=2 -C gic_distributor.ITS-shared-vPE-table=2 -C gic_distributor.ITS-vmovp-bit=1 -C gic_distributor.has_VPENDBASER-dirty-flag-on-load=1 -C gic_distributor.extended-ppi-count=32 -C gic_distributor.extended-spi-count=32 --application=<path_to_example>

Alternatively, replace all the -C options with

  -f <path_to_example_dir>/gicv4_all.params



Reference
===============================
[^1]: Arm Generic Interrupt Controller Architecture Specification. GIC architecture version 3 and version 4. Arm IHI 0069F (ID022020). Ch. 11.19.1 GITS_BASER<n>, ITS Translation Table Descriptors.
