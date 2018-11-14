//
// Copyright (c) 2018 Arm Limited. All rights reserved.
//



// Initial Setup & Entry point
//----------------------------------------------------------------

    .eabi_attribute Tag_ABI_align8_preserved,1
    .section  BOOT,"ax"
    .align 3
    
    .global Start    
Start:



// Reset Handler
//----------------------------------------------------------------  
    
.global Reset_Handler
.type Reset_Handler, "function"
Reset_Handler:   

    .global  Image$$ARM_LIB_STACKHEAP$$ZI$$Limit
    LDR SP, =Image$$ARM_LIB_STACKHEAP$$ZI$$Limit       

    // FP enable
    //------------------------

    //MRC     p15, 0, r0, c1, c0, 2      // Read Coprocessor Access Control Register (CPACR)
    //ORR     r0, r0, #(0xF << 20)       // Enable access to CP 10 & 11
    //MCR     p15, 0, r0, c1, c0, 2      // Write Coprocessor Access Control Register (CPACR)
    //ISB
    //MOV     r0, #0x40000000
    //VMSR    FPEXC, r0                   // Write FPEXC register, EN bit set    

    // Branch to __main
    //------------------------
    
    .global     __main
        B       __main
    
   
    
// Exception Vector Table & Handlers
//----------------------------------------------------------------

Vectors:

    LDR PC, Reset_Addr
    LDR PC, Undefined_Addr
    LDR PC, SVC_Addr
    LDR PC, Prefetch_Addr
    LDR PC, Abort_Addr
    B .                     // Reserved vector
    LDR PC, IRQ_Addr
    LDR PC, FIQ_Addr

    Reset_Addr:     .word   Reset_Handler
    Undefined_Addr: .word   Undefined_Handler
    SVC_Addr:       .word   SVC_Handler
    Prefetch_Addr:  .word   Prefetch_Handler
    Abort_Addr:     .word   Abort_Handler
    IRQ_Addr:       .word   IRQ_Handler
    FIQ_Addr:       .word   FIQ_Handler

    Undefined_Handler:      B   Undefined_Handler
    SVC_Handler:            B   SVC_Handler
    Prefetch_Handler:       B   Prefetch_Handler
    Abort_Handler:          B   Abort_Handler
    IRQ_Handler:            B   IRQ_Handler
    FIQ_Handler:            B   FIQ_Handler
