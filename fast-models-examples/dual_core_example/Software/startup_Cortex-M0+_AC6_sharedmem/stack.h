/*
** Copyright (c) 2006-2011 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/*
** This file contains the stack and heap addresses.
*/

//#define HEAP_BASE  0x20006000
#define HEAP_BASE   0x0001E000
#define STACK_BASE (HEAP_BASE + 0x1000)
#define HEAP_SIZE  ((STACK_BASE-HEAP_BASE)/2)
#define STACK_SIZE ((STACK_BASE-HEAP_BASE)/2)
