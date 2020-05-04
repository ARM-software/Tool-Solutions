//
// Copyright (c) 2018 Arm Limited. All rights reserved.
//



// Initial Setup & Entry point
//----------------------------------------------------------------


    .section  BOOT,"ax"     
    .align 3

    .global Start           
Start: 

    .global  Image$$ARM_LIB_STACKHEAP$$ZI$$Limit 
    LDR     x0, =Image$$ARM_LIB_STACKHEAP$$ZI$$Limit
    ADD     SP, x0, #0

    LDR x0, =Vectors     
    MSR VBAR_EL3, x0     

    // Set translation table base and attributes
    //------------------------

    .global   Image$$TT0_L1$$ZI$$Base
    .global   TT0_L2    
    LDR      x1, =Image$$TT0_L1$$ZI$$Base     
    MSR      TTBR0_EL3, x1                    

    MRS     x4, MPIDR_EL1
    LDR     x1, =0x101
    AND     x4, x4, x1

    LDR      x1, =0xFF44
    MSR      MAIR_EL3, x1

    // Set up TCR_EL3
    // ---------------

    LDR      x1, =0x0000000080803519
    MSR      TCR_EL3, x1      
    ISB
    LDR      x0, =Image$$TT0_L1$$ZI$$Base   
    LDR      x1, =TT0_L2 
    LDR      x2, =0x00000000000000003         
    ORR      x2, x2, x1                        // Combine template with L2 table Base address
    STR      x2, [x0, #0]                      // Write template into entry table[0]
    ADD      x2, x2, #0x1000                   // Move pointer on to the next table in memory
    STR      x2, [x0, #8]                      // Write template into entry table[1]
    ADD      x2, x2, #0x1000
    STR      x2, [x0, #16]                     // Write template into entry table[2]
    ADD      x2, x2, #0x1000
    STR      x2, [x0, #24]                     // Write template into entry table[3]
    DSB      SY

    // FP enable
    //------------------------

    MSR CPTR_EL3, XZR       // Disable trapping of accessing in EL3 and EL2.
    MSR CPTR_EL3, XZR
    MOV X1, #(0x3 << 20)    // FPEN disables trapping to EL1.
    MSR CPACR_EL1, X1       
    ISB
    
    // Branch to __main
    //------------------------

    .global __main
    LDR      x0, =__main
    BR       x0
    B __main

    
// Exception Vector Table & Handlers
//----------------------------------------------------------------

Vectors:

    B .                             // Current EL 32bits: Synchronous
    .balign 128          
    B .                             // IRQ/vIRQ
    .balign 128          
    B .                             // FIQ/vFIQ
    .balign 128          
    B .                             // Error/vError
    .balign 128          
    B .                             // Current EL 64bits: Synchronous
    .balign 128          
    B .                             // IRQ/vIRQ
    .balign 128          
    B .                             // FIQ/vFIQ
    .balign 128          
    B .                             // Error/vError
    .balign 128          
    B .                             // Lower EL SPx:      Synchronous
    .balign 128          
    B .                             // IRQ/vIRQ
    .balign 128          
    B .                             // FIQ/vFIQ
    .balign 128          
    B .                             // Error/vError
    .balign 128          
    B .                             // Lower EL SP0:      Synchronous
    .balign 128          
    B .                             // IRQ/vIRQ
    .balign 128          
    B .                             // FIQ/vFIQ
    .balign 128         
    B .                             // Error/vError

