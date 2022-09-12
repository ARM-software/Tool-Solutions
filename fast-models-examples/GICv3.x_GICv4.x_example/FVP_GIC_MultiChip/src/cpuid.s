/*!
 * \file     SystemUtils.S
 * \brief    System utility functions.
 *
 *  Copyright 2018 ARM Limited. All rights reserved.
 */

#include "ArchitecturalConstants.h"

    .text
    .cfi_sections .debug_frame  // put stack frame info into .debug_frame instead of .eh_frame

    .global EnableCachesEL1
    .global DisableCachesEL1
    .global InvalidateUDCaches
    .global GetMIDR
    .global GetMPIDR
    .global GetCPUID
    .global toHandlerMode
    .global toThreadMode
    .global changeCurrentStack
    .global readSP
    .global doWriteNSBit

// ------------------------------------------------------------

//
// void EnableCachesEL1(void)
//
//    enable Instruction and Data caches
//
    .type EnableCachesEL1, "function"
    .cfi_startproc
EnableCachesEL1:

    mrs x0, SCTLR_EL1
    // orr x0, x0, #SCTLR_ELx_I
    // orr x0, x0, #SCTLR_ELx_C
    msr SCTLR_EL1, x0

    isb
    ret
    .cfi_endproc


// ------------------------------------------------------------

    .type DisableCachesEL1, "function"
    .cfi_startproc
DisableCachesEL1:

    mrs x0, SCTLR_EL1
    // bic x0, x0, #SCTLR_ELx_I
    // bic x0, x0, #SCTLR_ELx_C
    msr SCTLR_EL1, x0

    isb
    ret
    .cfi_endproc


// ------------------------------------------------------------

//
// void InvalidateUDCaches(void)
//
//    Invalidate data and unified caches
//
    .type InvalidateUDCaches, "function"
    .cfi_startproc
InvalidateUDCaches:
    // From the Armv8-A Architecture Reference Manual

    dmb  ish                   // ensure all prior inner-shareable accesses have been observed

    mrs  x0, CLIDR_EL1
    and  w3, w0, #0x07000000   // get 2 x level of coherence
    lsr  w3, w3, #23
    cbz  w3, finished
    mov  w10, #0               // w10 = 2 x cache level
    mov  w8, #1                // w8 = constant 0b1
loop_level:
    add  w2, w10, w10, lsr #1  // calculate 3 x cache level
    lsr  w1, w0, w2            // extract 3-bit cache type for this level
    and  w1, w1, #0x7
    cmp  w1, #2
    b.lt next_level            // no data or unified cache at this level
    msr  CSSELR_EL1, x10       // select this cache level
    isb                        // synchronize change of csselr
    mrs  x1, CCSIDR_EL1        // read ccsidr
    and  w2, w1, #7            // w2 = log2(linelen)-4
    add  w2, w2, #4            // w2 = log2(linelen)
    ubfx w4, w1, #3, #10       // w4 = max way number, right aligned
    clz  w5, w4                // w5 = 32-log2(ways), bit position of way in dc operand
    lsl  w9, w4, w5            // w9 = max way number, aligned to position in dc operand
    lsl  w16, w8, w5           // w16 = amount to decrement way number per iteration
loop_way:
    ubfx w7, w1, #13, #15      // w7 = max set number, right aligned
    lsl  w7, w7, w2            // w7 = max set number, aligned to position in dc operand
    lsl  w17, w8, w2           // w17 = amount to decrement set number per iteration
loop_set:
    orr  w11, w10, w9          // w11 = combine way number and cache number ...
    orr  w11, w11, w7          // ... and set number for dc operand
    dc   isw, x11              // do data cache invalidate by set and way
    subs w7, w7, w17           // decrement set number
    b.ge loop_set
    subs x9, x9, x16           // decrement way number
    b.ge loop_way
next_level:
    add  w10, w10, #2          // increment 2 x cache level
    cmp  w3, w10
    b.gt loop_level
    dsb  sy                    // ensure completion of previous cache maintenance operation
    isb
finished:
    ret
    .cfi_endproc


// ------------------------------------------------------------

//
// ID Register functions
//

    .type GetMIDR, "function"
    .cfi_startproc
GetMIDR:

    mrs x0, MIDR_EL1
    ret
    .cfi_endproc


    .type GetMPIDR, "function"
    .cfi_startproc
GetMPIDR:

    mrs x0, MPIDR_EL1
    ret
    .cfi_endproc


    .type GetCPUID, "function"
    .cfi_startproc
GetCPUID:

    MRS      x0, MPIDR_EL1
    AND      x0, x0, #0xFF                     // Mask off to leave Aff0
    ret
    .cfi_endproc

    .type toHandlerMode, "function"
    .cfi_startproc
toHandlerMode:
    msr SPSEL, #1
    br x0
    .cfi_endproc

    .type toThreadMode, "function"
    .cfi_startproc
toThreadMode:
    msr SPSEL, #0
    br x0
    .cfi_endproc

    .type changeCurrentStack, "function"
    .cfi_startproc
changeCurrentStack:
    mov sp, x1
    br x0
    .cfi_endproc

    .type readSP, "function"
    .cfi_startproc
readSP:
    mov x0, sp
    ret
    .cfi_endproc

    .type doWriteNSBit, "function"
    .cfi_startproc
doWriteNSBit:
    mrs x1, scr_el3
    cbnz x0, setNSbit
    bic x1, x1, 1
    msr scr_el3, x1
    ret
setNSbit:
    orr x1, x1, 1
    msr scr_el3, x1
    ret
    .cfi_endproc
