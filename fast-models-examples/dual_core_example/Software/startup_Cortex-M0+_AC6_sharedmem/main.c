/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/* This file contains the main() program that sets the vector table location, displays a welcome message,
starts the SysTick timer, initializes the Process Stack Pointer, changes Thread mode
to use the Process Stack, then runs the main application (sorts) */


#include "scs.h"
#include "timer.h"
#include <stdio.h>
#include "stack.h"
#include <arm_acle.h>

extern unsigned int Image$$PROCESS_STACK$$ZI$$Limit;

extern void compare_sorts(void);

/* Initialize stack and heap symbols for microlib */
const unsigned int __initial_sp __attribute__((used)) = STACK_BASE;
const unsigned int __heap_base __attribute__((used))  = HEAP_BASE;
const unsigned int __heap_limit __attribute__((used)) = (HEAP_BASE + HEAP_SIZE);

volatile unsigned int Semaphore __attribute__((section("shared_section.__at_0x20100000")));

__attribute__((noreturn)) int main(void)
{
    /* Processor starts-up in Privileged Thread Mode using Main Stack */

    /* Display a welcome message via semihosting */
    printf("Cortex-M0+ bare-metal startup example\n");

    /* Initialize SysTick Timer */
    SysTick_init();

    /* Initialize Process Stack Pointer using linker-generated symbol from scatter-file */
    //__arm_wsr("PSP", (unsigned int) &Image$$PROCESS_STACK$$ZI$$Limit);

    /* Change Thread mode use the Process Stack */
    //unsigned int read_ctrl = __arm_rsr("CONTROL");
    //__arm_wsr("CONTROL", read_ctrl | 2);

    /* Flush and refill pipeline before proceeding */
    //__isb(0xf);

    /* Run the main application (sorts) */
    compare_sorts();

    while( 1 )
    {
        /* Loop forever */
    	for(int i=0; i<2000000; i++);
    	Semaphore++;
    	printf("M0+: Semaphore Updated to: %d\n", Semaphore);
    }
}
