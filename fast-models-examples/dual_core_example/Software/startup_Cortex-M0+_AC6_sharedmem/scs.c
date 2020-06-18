/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/* This file contains System Control Space (SCS) Registers */


/* SCS Registers */
#include "scs.h"

/* SCS Registers in separate section so it can be placed correctly using scatter file */
SCS_t SCS __attribute__((section(".bss.scs_registers")));


void NVIC_enableISR(unsigned isr)
{
    /* No need to do a read-modify-write; writing a 0 to the enable register does nothing */
    SCS.NVIC.Enable[ (isr/32) ] = 1<<(isr % 32);
}
