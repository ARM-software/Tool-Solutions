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



// Reset Handlers (EL1 and EL2)
//---------------------------------------------------------------- 

EL2_Reset_Handler:

    .global  Image$$ARM_LIB_STACKHEAP$$ZI$$Limit
    LDR SP, =Image$$ARM_LIB_STACKHEAP$$ZI$$Limit  

    
    // Go to SVC mode
    //------------------------        
    
    MRS r0, cpsr
    MOV r1, #0x13
    BFI r0, r1, #0, #5
    MSR spsr_hyp, r0
    LDR r0, =EL1_Reset_Handler
    MSR elr_hyp, r0
    DSB
    ISB
    ERET

EL1_Reset_Handler:

    // Branch to __main
    //------------------------        
    
    .global     __main
        B       __main

            
    
// Exception Vector Table & Handlers
//----------------------------------------------------------------

EL2_Vectors:

    LDR PC, EL2_Reset_Addr
    LDR PC, EL2_Undefined_Addr
    LDR PC, EL2_HVC_Addr
    LDR PC, EL2_Prefetch_Addr
    LDR PC, EL2_Abort_Addr
    LDR PC, EL2_HypModeEntry_Addr
    LDR PC, EL2_IRQ_Addr
    LDR PC, EL2_FIQ_Addr

    EL2_Reset_Addr:         .word    EL2_Reset_Handler
    EL2_Undefined_Addr:     .word    EL2_Undefined_Handler
    EL2_HVC_Addr:           .word    EL2_HVC_Handler
    EL2_Prefetch_Addr:      .word    EL2_Prefetch_Handler
    EL2_Abort_Addr:         .word    EL2_Abort_Handler
    EL2_HypModeEntry_Addr:  .word    EL2_HypModeEntry_Handler
    EL2_IRQ_Addr:           .word    EL2_IRQ_Handler
    EL2_FIQ_Addr:           .word    EL2_FIQ_Handler

    EL2_Undefined_Handler:          B   EL2_Undefined_Handler
    EL2_HVC_Handler:                B   EL2_HVC_Handler
    EL2_Prefetch_Handler:           B   EL2_Prefetch_Handler
    EL2_Abort_Handler:              B   EL2_Abort_Handler
    EL2_HypModeEntry_Handler:       B   EL2_HypModeEntry_Handler
    EL2_IRQ_Handler:                B   EL2_IRQ_Handler
    EL2_FIQ_Handler:                B   EL2_FIQ_Handler

    
EL1_Vectors:

    LDR PC, EL1_Reset_Addr
    LDR PC, EL1_Undefined_Addr
    LDR PC, EL1_SVC_Addr
    LDR PC, EL1_Prefetch_Addr
    LDR PC, EL1_Abort_Addr
    LDR PC, EL1_Reserved
    LDR PC, EL1_IRQ_Addr
    LDR PC, EL1_FIQ_Addr

    EL1_Reset_Addr:     .word    EL1_Reset_Handler
    EL1_Undefined_Addr: .word    EL1_Undefined_Handler
    EL1_SVC_Addr:       .word    EL1_SVC_Handler
    EL1_Prefetch_Addr:  .word    EL1_Prefetch_Handler
    EL1_Abort_Addr:     .word    EL1_Abort_Handler
    EL1_Reserved_Addr:  .word    EL1_Reserved
    EL1_IRQ_Addr:       .word    EL1_IRQ_Handler
    EL1_FIQ_Addr:       .word    EL1_FIQ_Handler

    EL1_Undefined_Handler:          B   EL1_Undefined_Handler
    EL1_SVC_Handler:                B   EL1_SVC_Handler
    EL1_Prefetch_Handler:           B   EL1_Prefetch_Handler
    EL1_Abort_Handler:              B   EL1_Abort_Handler
    EL1_Reserved:                   B   EL1_Reserved
    EL1_IRQ_Handler:                B   EL1_IRQ_Handler
    EL1_FIQ_Handler:                B   EL1_FIQ_Handler