/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/*
** This file implements SysTick initialization and SysTick exception handler.
*/

#include "timer.h"
#include "scs.h"
#include <stdio.h>

#define RELOAD 7200000

static unsigned int ticks = 0;


/* SysTick initialization */

void SysTick_init(void)
{
#if (RELOAD > 0xFFFFFF)
   #error "Reload Value too large!"
#else
    *SysTickLoad  = RELOAD; /* reload value on timeout */
    *SysTickValue = 0;      /* clear current value */

    /* Start timer, with interrupts enabled */
    *SysTickCtrl = SysTickEnable | SysTickInterrupt | SysTickClkSource;
#endif
}


/* SysTick exception handler */
/* All exceptions are handled in Handler mode.  Processor state is automatically
pushed onto the stack when an exception occurs, and popped from the stack at
the end of the handler */

__attribute__((interrupt)) void SysTickHandler(void)
{
    ticks++;
    printf("SysTick interrupt %d\n", ticks);
    fflush(stdout);
}
