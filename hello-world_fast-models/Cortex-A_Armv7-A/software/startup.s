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
    LDR     SP, =Image$$ARM_LIB_STACKHEAP$$ZI$$Limit

    LDR     r0, =Vectors
    MCR     p15, 0, r0, c12, c0, 0

    // Set translation table base and attributes
    //------------------------
    
    .global  Image$$CODE$$Base
    .global  Image$$TTB$$ZI$$Base
    MOV     r0,#0x0
    MCR     p15, 0, r0, c2, c0, 2
    LDR     r0,=Image$$TTB$$ZI$$Base
    MOV     r1, #0x08                  
    ORR     r1,r1,#0x40                
    ORR     r0,r0,r1
    MCR     p15, 0, r0, c2, c0, 0

    // Page table generation
    //------------------------
    
    LDR     r0,=Image$$TTB$$ZI$$Base
    LDR     r1,=0xfff                       // loop counter
    LDR     r2,=0xde2

    init_ttb_1:
    
        ORR     r3, r2, r1, LSL#20          // R3 now contains full level1 descriptor to write
        ORR     r3, r3, #0x10               // Set XN bit
        STR     r3, [r0, r1, LSL#2]         // Str table entry at TTB base + loopcount*4
        SUBS    r1, r1, #1                  // Decrement loop counter
        BPL     init_ttb_1

        LDR     r1,=Image$$CODE$$Base       // Base physical address of code segment
        LSR     r1, #20                     // Shift right to align to 1MB boundaries
        ORR     r3, r2, r1, LSL#20          // Setup the initial level1 descriptor again
        ORR     r3, r3, #0xc                // Set CB bits
        ORR     r3, r3, #0x1000             // Set TEX bit 12      
        STR     r3, [r0, r1, LSL#2]         // str table entry
        
    // Setup domain control register - Enable all domains to client mode
    //------------------------

    MRC     p15, 0, r0, c3, c0, 0           // Read Domain Access Control Register
    LDR     r0, =0x55555555                 // Initialize every domain entry to b01 (client)
    MCR     p15, 0, r0, c3, c0, 0           // Write Domain Access Control Register

    // FP enable
    //------------------------
    //MRC     p15, 0, r0, c1, c0, 2      // Read Coprocessor Access Control Register (CPACR)
    //ORR     r0, r0, #0x00f00000        // Enable access to CP 10 & 11
    //MCR     p15, 0, r0, c1, c0, 2      // Write Coprocessor Access Control Register (CPACR)
    //ISB
    //MOV     r0, #0x40000000
    //VMSR    FPEXC, r0                  // Write FPEXC register, EN bit set
    
            

    // Branch to __main
    //------------------------

    .global __main     
    LDR     r12,=__main                     // Save this in register for possible long jump
    BX      r12                             // Branch to __main  C library entry point
   
   
        
// Exception Vector Table & Handlers
//----------------------------------------------------------------

Vectors:
    LDR PC, Reset_Addr
    LDR PC, Undefined_Addr
    LDR PC, SVC_Addr
    LDR PC, Prefetch_Addr
    LDR PC, Abort_Addr
    LDR PC, Hypervisor_Addr
    LDR PC, IRQ_Addr
    LDR PC, FIQ_Addr

    Reset_Addr:      .word     Reset_Handler
    Undefined_Addr:  .word     Undefined_Handler
    SVC_Addr:        .word     SVC_Handler
    Prefetch_Addr:   .word     Prefetch_Handler
    Abort_Addr:      .word     Abort_Handler
    Hypervisor_Addr: .word     Hypervisor_Handler
    IRQ_Addr:        .word     IRQ_Handler
    FIQ_Addr:        .word     FIQ_Handler


    Undefined_Handler:      B   Undefined_Handler
    SVC_Handler:            B   SVC_Handler
    Prefetch_Handler:       B   Prefetch_Handler
    Abort_Handler:          B   Abort_Handler
    Hypervisor_Handler:     B   Hypervisor_Handler
    IRQ_Handler:            B   IRQ_Handler
    FIQ_Handler:            B   FIQ_Handler
            