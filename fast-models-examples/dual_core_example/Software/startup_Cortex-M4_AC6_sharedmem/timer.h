/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/*
** SysTick Header file.
**
** Defines SysTick Registers and Masks
*/

#ifndef TIMER_H_
#define TIMER_H_

void SysTick_init(void);
__attribute__((interrupt)) void SysTickHandler(void);

/* SysTick Registers */
#define SysTickCtrl  (volatile int*)0xE000E010
#define SysTickLoad  (volatile int*)0xE000E014
#define SysTickValue (volatile int*)0xE000E018
#define SysTickCalib (volatile int*)0xE000E01c

/* SysTick Masks */
#define SysTickCountFlag (1<<16)
#define SysTickClkSource (1<<2)
#define SysTickInterrupt (1<<1)
#define SysTickEnable    (1<<0)

#endif
