/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/* This file contains System Control Space (SCS) Registers and MPU initialization */


/* SCS Registers and MPU Masks */
#include "scs.h"
#include <arm_acle.h>

/* SCS Registers in separate section so it can be placed correctly using scatter file */
SCS_t SCS __attribute__((section(".bss.scs_registers")));


/* Linker symbols from scatter-file */
extern unsigned int Image$$VECTORS$$Base;
extern unsigned int Image$$DATA$$Base;
extern unsigned int Image$$ARM_LIB_STACKHEAP$$Base;
extern unsigned int Image$$PROCESS_STACK$$ZI$$Base;
extern unsigned int Image$$SHARED_MEM$$Base;


/* Setup MPU regions, enable the MPU, enable hardware stack alignment */
void SCS_init(void)
{
    /* Configure region 1 to cover VECTORS and CODE (Executable, Read-only) */
    /* Start address, Region field valid, Region number */
    SCS.MPU.RegionBaseAddr = ((unsigned int) &Image$$VECTORS$$Base) | REGION_VALID | 1;
    /* Access control bits, Size, Enable */
    SCS.MPU.RegionAttrSize = RO | CACHEABLE | BUFFERABLE | REGION_16K | REGION_ENABLED;

    /* Configure a region to cover DATA in RAM (Executable, Read-Write) */
    SCS.MPU.RegionBaseAddr = ((unsigned int) &Image$$DATA$$Base) | REGION_VALID | 2;
    SCS.MPU.RegionAttrSize = FULL_ACCESS | CACHEABLE | BUFFERABLE | REGION_8K | REGION_ENABLED;

    /* Configure a region to cover Heap and Main Stack (Not Executable, Read-Write) */
    SCS.MPU.RegionBaseAddr = ((unsigned int) &Image$$ARM_LIB_STACKHEAP$$Base) | REGION_VALID | 3;
    SCS.MPU.RegionAttrSize = NOT_EXEC | FULL_ACCESS | CACHEABLE | BUFFERABLE | REGION_4K | REGION_ENABLED;

    /* Configure a region to cover Process Stack (Not Executable, Read-Write) */
    SCS.MPU.RegionBaseAddr = ((unsigned int) &Image$$PROCESS_STACK$$ZI$$Base) | REGION_VALID | 4;
    SCS.MPU.RegionAttrSize = NOT_EXEC | FULL_ACCESS | CACHEABLE | BUFFERABLE | REGION_4K | REGION_ENABLED;

    /* Configure a region to cover Process Stack (Not Executable, Read-Write) */
    SCS.MPU.RegionBaseAddr = ((unsigned int) &Image$$SHARED_MEM$$Base) | REGION_VALID | 5;
    SCS.MPU.RegionAttrSize = FULL_ACCESS | CACHEABLE | BUFFERABLE | REGION_4K | REGION_ENABLED;

    /* Enable the MPU */
    SCS.MPU.Ctrl |= 1;

    /* Enable hardware stack alignment */
    SCS.CCR |= 0x200;

    /* Force Memory Writes before continuing */
    __dsb(0xf);
    /* Flush and refill pipeline with updated permissions */
    __isb(0xf);
}


void NVIC_enableISR(unsigned isr)
{
    /* No need to do a read-modify-write; writing a 0 to the enable register does nothing */
    SCS.NVIC.Enable[ (isr/32) ] = 1<<(isr % 32);
}
