/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/* This file contains the main() program that sets the vector table location, displays a welcome message,
initializes the MPU, starts the SysTick timer, initializes the Process Stack Pointer, changes Thread mode
to Unprivileged and to use the Process Stack, then runs the main application (sorts) */


#include "scs.h"
#include "timer.h"
#include <stdio.h>
#include <math.h>
#include <arm_acle.h>

#define VectorTableOffsetRegister 0xE000ED08
extern unsigned int Image$$VECTORS$$Base;
extern unsigned int Image$$PROCESS_STACK$$ZI$$Limit;

extern void compare_sorts(void);
float calculate( float a, float b);


/* Enable the FPU if required */
#ifdef __ARM_FP
extern void $Super$$__rt_lib_init(void);

void $Sub$$__rt_lib_init(void)
{
    /* Enable the FPU in both privileged and user modes by setting bits 20-23 to enable CP10 and CP11 */
    SCS.CPACR = SCS.CPACR | (0xF << 20);
    $Super$$__rt_lib_init();
}
#endif

volatile unsigned int Semaphore __attribute__((section("shared_section.__at_0x20100000")));

__attribute__((noreturn)) int main(void)
{
    /* Processor starts-up in Privileged Thread Mode using Main Stack */

    /* Tell the processor the location of the vector table, obtained from the scatter file */
    *(volatile unsigned int *)(VectorTableOffsetRegister) = (unsigned int) &Image$$VECTORS$$Base;

    /* Display a welcome message via semihosting */
    printf("Cortex-M4 bare-metal startup example\n");

    /* Initialize MPU */
    //SCS_init();

    /* Perform a float calculation */
#ifdef __ARM_FP
    printf("Calculating using the hardware floating point unit (FPU)\n");
#else
    printf("Calculating using the software floating point library (no FPU)\n");
#endif
    printf("Float result should be 80.406250\n");
    printf("Float result is        %f\n", calculate(1.0f, 2.5f));

    /* Initialize SysTick Timer */
    SysTick_init();

    /* Initialize Process Stack Pointer */
    //__arm_wsr("PSP", (unsigned int) &Image$$PROCESS_STACK$$ZI$$Limit);

    /* Change Thread mode to Unprivileged and to use the Process Stack */
    //unsigned int read_ctrl = __arm_rsr("CONTROL");
    //__arm_wsr("CONTROL", read_ctrl | 3);

    /* Flush and refill pipeline with unprivileged permissions */
    //__isb(0xf);

    /* Run the main application (sorts) */
    compare_sorts();

    while( 1 )
    {
        /* Loop forever */
    	printf("M4: Semaphore value is        %d\n", Semaphore);
    	for(int i=0; i<1000000; i++);
    }
}


/* Float calculation to demonstrate the Cortex-M4's FPU, including float Fused Multiply Add (fma) */
float calculate( float a, float b)
{
    a = a + 3.25f;
    b = b * 4.75f;
    return fmaf(a + b, a, b);
    // result should be (4.25+11.875)*4.25 + 11.875 = 80.40625
}
