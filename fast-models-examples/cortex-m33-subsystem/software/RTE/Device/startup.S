/**************************************************************************//**
 * @file     startup_ARMCM33.s
 * @brief    CMSIS Core Device Startup File for
 *           ARMCM33 Device Series
 * @version  V5.00
 * @date     21. October 2016
 ******************************************************************************/
/*
 * Copyright (c) 2009-2016 ARM Limited. All rights reserved.
 *
 * This is a hand conversion from ARM assembler to GNU assembler of the
 * startup_ARMCM33.s file supplied in the Cortex-M33 startup code pack.
 */

	.syntax	unified
	.arch	armv7-m


// <h> Stack Configuration
//   <o> Stack Size (in Bytes) <0x0-0xFFFFFFFF:8>
// </h>

	.section .stack
	.balign	8
#ifdef __STACK_SIZE
	.equ	Stack_Size, __STACK_SIZE
#else
	.equ	Stack_Size, 0x00000400
#endif
	.globl	__StackTop
	.globl	__StackLimit

__StackLimit:
	.space	Stack_Size
	.size	__StackLimit, . - __StackLimit
__StackTop:
	.size	__StackTop, . - __StackTop


// <h> Heap Configuration
//   <o>  Heap Size (in Bytes) <0x0-0xFFFFFFFF:8>
// </h>

	.section .heap
	.balign	8
#ifdef __HEAP_SIZE
	.equ	Heap_Size, __HEAP_SIZE
#else
	.equ	Heap_Size, 0x00000C00
#endif
	.globl	__HeapBase
	.globl	__HeapLimit
__HeapBase:
	.if	Heap_Size
    	.space	Heap_Size
	.endif
	.size	__HeapBase, . - __HeapBase
__HeapLimit:
	.size	__HeapLimit, . - __HeapLimit


// Vector Table Mapped to Address 0 at Reset

	.section .vectors
	.balign 4
	.globl	__Vectors
__Vectors:
	.long	__StackTop            /* Top of Stack */
	.long	Reset_Handler         /* Reset Handler */
	.long	NMI_Handler           /* NMI Handler */
	.long	HardFault_Handler     /* Hard Fault Handler */
	.long	MemManage_Handler     /* MPU Fault Handler */
	.long	BusFault_Handler      /* Bus Fault Handler */
	.long	UsageFault_Handler    /* Usage Fault Handler */
    .long   SecureFault_Handler   /* Secure Fault Handler */
	.long	0                     /* Reserved */
	.long	0                     /* Reserved */
	.long	0                     /* Reserved */
	.long	SVC_Handler           /* SVCall Handler */
	.long	DebugMon_Handler      /* Debug Monitor Handler */
	.long	0                     /* Reserved */
	.long	PendSV_Handler        /* PendSV Handler */
	.long	SysTick_Handler       /* SysTick Handler */

	/* External interrupts */
	.long	WDT_IRQHandler        /*  0:  Watchdog Timer            */
	.long	RTC_IRQHandler        /*  1:  Real Time Clock           */
	.long	TIM0_IRQHandler       /*  2:  Timer0 / Timer1           */
	.long	TIM2_IRQHandler       /*  3:  Timer2 / Timer3           */
	.long	MCIA_IRQHandler       /*  4:  MCIa                      */
	.long	MCIB_IRQHandler       /*  5:  MCIb                      */
	.long	UART0_IRQHandler      /*  6:  UART0 - DUT FPGA          */
	.long	UART1_IRQHandler      /*  7:  UART1 - DUT FPGA          */
	.long	UART2_IRQHandler      /*  8:  UART2 - DUT FPGA          */
	.long	UART4_IRQHandler      /*  9:  UART4 - not connected     */
	.long	AACI_IRQHandler       /* 10: AACI / AC97                */
	.long	CLCD_IRQHandler       /* 11: CLCD Combined Interrupt    */
	.long	ENET_IRQHandler       /* 12: Ethernet                   */
	.long	USBDC_IRQHandler      /* 13: USB Device                 */
	.long	USBHC_IRQHandler      /* 14: USB Host Controller        */
	.long	CHLCD_IRQHandler      /* 15: Character LCD              */
	.long	FLEXRAY_IRQHandler    /* 16: Flexray                    */
	.long	CAN_IRQHandler        /* 17: CAN                        */
	.long	LIN_IRQHandler        /* 18: LIN                        */
	.long	I2C_IRQHandler        /* 19: I2C ADC/DAC                */
	.long	0                     /* 20: Reserved                   */
	.long	0                     /* 21: Reserved                   */
	.long	0                     /* 22: Reserved                   */
	.long	0                     /* 23: Reserved                   */
	.long	0                     /* 24: Reserved                   */
	.long	0                     /* 25: Reserved                   */
	.long	0                     /* 26: Reserved                   */
	.long	0                     /* 27: Reserved                   */
	.long	CPU_CLCD_IRQHandler   /* 28: Reserved - CPU FPGA CLCD   */
	.long	0                     /* 29: Reserved - CPU FPGA        */
	.long	UART3_IRQHandler      /* 30: UART3    - CPU FPGA        */
	.long	SPI_IRQHandler        /* 31: SPI Touchscreen - CPU FPGA */

	.size	__Vectors, . - __Vectors

	.text


// Reset Handler
	.thumb
	.thumb_func
	.balign	4
	.global Reset_Handler
	.weak Reset_Handler
	.type Reset_Handler, "function"
 Reset_Handler:	 
	.global  SystemInit
	.global  __main
	    bl  SystemInit
	    bl  __main
    .pool
	.size Reset_Handler, . - Reset_Handler


// Default handler (branch to self)
	.thumb_func
	.balign	2
	.weak	Default_Handler
	.type	Default_Handler, %function
Default_Handler:
	b	.
	.size	Default_Handler, . - Default_Handler


/*    Macro to define default handlers. Default handler
 *    will be weak symbol and just dead loops. They can be
 *    overwritten by other handlers */
	.macro	def_irq_handler	handler_name
	    .thumb_func
	    .balign	2
	    .weak	\handler_name
	    .type	\handler_name, %function
        \handler_name:
	        b	.
	    .size \handler_name, . - \handler_name
	.endm

	def_irq_handler	NMI_Handler
	def_irq_handler	HardFault_Handler
	def_irq_handler	MemManage_Handler
	def_irq_handler	BusFault_Handler
	def_irq_handler	UsageFault_Handler
	def_irq_handler	SecureFault_Handler
	def_irq_handler	SVC_Handler
	def_irq_handler	DebugMon_Handler
	def_irq_handler	PendSV_Handler
	def_irq_handler	SysTick_Handler

	def_irq_handler	WDT_IRQHandler
	def_irq_handler	RTC_IRQHandler
	def_irq_handler	TIM0_IRQHandler
	def_irq_handler	TIM2_IRQHandler
	def_irq_handler	MCIA_IRQHandler
	def_irq_handler	MCIB_IRQHandler
	def_irq_handler	UART0_IRQHandler
	def_irq_handler	UART1_IRQHandler
	def_irq_handler	UART2_IRQHandler
	def_irq_handler	UART3_IRQHandler
	def_irq_handler	UART4_IRQHandler
	def_irq_handler	AACI_IRQHandler
	def_irq_handler	CLCD_IRQHandler
	def_irq_handler	ENET_IRQHandler
	def_irq_handler	USBDC_IRQHandler
	def_irq_handler	USBHC_IRQHandler
	def_irq_handler	CHLCD_IRQHandler
	def_irq_handler	FLEXRAY_IRQHandler
	def_irq_handler	CAN_IRQHandler
	def_irq_handler	LIN_IRQHandler
	def_irq_handler	I2C_IRQHandler
	def_irq_handler	CPU_CLCD_IRQHandler
	def_irq_handler	SPI_IRQHandler


// User Initial Stack & Heap

    .ifdef __MICROLIB

	    .global __initial_sp
	    .global __heap_base
	    .global __heap_limit

    .else

	    .global __use_two_region_memory
	    .global __user_initial_stackheap

    	.balign	4
	    .type __user_initial_stackheap, "function"
         __user_initial_stackheap:	 
                    LDR     R0, = __HeapBase
                    LDR     R1, = __StackTop
                    LDR     R2, = __HeapLimit
                    LDR     R3, = __StackLimit
                    BX      LR
	    .size __user_initial_stackheap, . - __user_initial_stackheap

    .endif

