//==================================================================
// GICv4.1 Example, code for secondary core (0.0.0.1)
//
// Copyright (C) Arm Limited, 2019 All rights reserved.
//
// The example code is provided to you as an aid to learning when working
// with Arm-based technology, including but not limited to programming tutorials.
// Arm hereby grants to you, subject to the terms and conditions of this Licence,
// a non-exclusive, non-transferable, non-sub-licensable, free-of-charge licence,
// to use and copy the Software solely for the purpose of demonstration and
// evaluation.
//
// You accept that the Software has not been tested by Arm therefore the Software
// is provided �as is�, without warranty of any kind, express or implied. In no
// event shall the authors or copyright holders be liable for any claim, damages
// or other liability, whether in action or contract, tort or otherwise, arising
// from, out of or in connection with the Software or the use of Software.
//==================================================================

  .section  secondary_boot,"ax"
  .align 3

// ------------------------------------------------------------

.equ AArch32_Mode_USR,     0x10
.equ AArch32_Mode_FIQ,     0x11
.equ AArch32_Mode_IRQ,     0x12
.equ AArch32_Mode_SVC,     0x13
.equ AArch32_Mode_ABT,     0x17
.equ AArch32_Mode_UNDEF,   0x1B
.equ AArch32_Mode_SYS,     0x1F
.equ AArch32_Mode_HYP,     0x1A
.equ AArch32_Mode_MON,     0x16

.equ AArch64_EL2_SP2,      0x09    // EL2h
.equ AArch64_EL2_SP0,      0x08    // EL2t
.equ AArch64_EL1_SP1,      0x05    // EL1h
.equ AArch64_EL1_SP0,      0x04    // EL1t
.equ AArch64_EL0_SP0,      0x00

.equ AArch64_SPSR_I,       (1 << 7)
.equ AArch64_SPSR_F,       (1 << 6)

.equ AArch32_State_Thumb,  0x20
.equ AArch32_State_ARM,    0x00

// ------------------------------------------------------------

.equ GICDbase,           0x2F000000

.equ GICD_CTLRoffset,        0x0
.equ GICD_CTLR.ARE_S,       (1<<4)
.equ GICD_CTLR.ARE_NS,      (1<<5)
.equ GICD_CTLR.EnableG0,     1
.equ GICD_CTLR.EnableG1NS,  (1<<1)
.equ GICD_CTLR.EnableG1S,   (1<<2)
.equ GICD_CTLR.DS,          (1<<6)

.equ GICD_IGROUPRoffset,     0x080
.equ GICD_ISENABLERoffset,   0x100
.equ GICD_ICENABLERoffset,   0x180
.equ GICD_ISPENDRoffset,     0x200
.equ GICD_ICPENDRoffset,     0x280
.equ GICD_IPRIORITYRoffset,  0x400
.equ GICD_ICFGRoffset,       0xC00
.equ GICD_IGRPMODRoffset,    0xD00
.equ GICD_NSACRoffset,       0xE00
.equ GICD_SGIR,              0xF00

.equ GICD_IROUTERoffset,     0x6000
.equ GICD_IROUTER.RM,       (1<<31)

// ------------------------------------------------------------

.equ ICC_SRE_ELn.Enable,    (1<<3)
.equ ICC_SRE_ELn.SRE,       (1)

// ------------------------------------------------------------

.equ RDbase,                0x2F140000

.equ GICR_WAKERoffset,           0x14
.equ GICR_WAKER.ProcessorSleep,  (1<<2)
.equ GICR_WAKER.ChildrenAsleep,  (1<<3)

.equ GICR_CTLRoffset,       0x0

// ------------------------------------------------------------

.equ SGIbase,                (RDbase + 0x10000)

.equ GICR_IGROUPRoffset,     0x080
.equ GICR_ISENABLERoffset,   0x100
.equ GICR_ICENABLERoffset,   0x180
.equ GICR_ISPENDRoffset,     0x200
.equ GICR_ICPENDRoffset,     0x280
.equ GICR_IPRIORITYRoffset,  0x400
.equ GICR_ICFGRoffset,       0xC00
.equ GICR_IGRPMODRoffset,    0xD00
.equ GICR_NSACRoffset,       0xE00

// ------------------------------------------------------------

  .global secondary
  .type secondary, @function
secondary:

  //
  // Install vector tables
  //
  LDR     x0, =el1_vectors
  MSR     VBAR_EL2, x0
  MSR     VBAR_EL1, x0


  // NOTE: Nothing will happen at this point, as the PE is not configured

  //
  // Mark core as awake in GICR_WAKER
  //
  MOV      x0, #RDbase
  MOV      x1, #GICR_WAKERoffset
  ADD      x1, x1, x0
  STR      wzr, [x1]
  DSB      SY
wait:                       // We now have to wait for ChildrenAsleep to read 0
  LDR      w0, [x1]
  AND      w0, w0, #0x6
  CBNZ     w0, wait


  //
  // Set Priority Mask
  //
  MOV     w0, #0xFF
  MSR     ICC_PMR_EL1, x0


  //
  // Set Group enables
  //
  MOV     w0, #3
  MSR     ICC_IGRPEN1_EL3, x0
  MSR     ICC_IGRPEN0_EL1, x0


  //
  // Enter NS.EL1
  //

  // Put SCTLR_EL1/2 into known state
  MSR      SCTLR_EL1, xzr
  MSR      SCTLR_EL2, xzr

  // Set up SCR_EL3
  MOV      x0, #1
  ORR      w0, w0, #(1 << 10)    // Set RW bit (EL1 is AArch64, as this is the Secure world)
  MSR      SCR_EL3, x0           // Set NS bit, lower ELs are Non-secure

  // Set up HCR_EL2
  MOV      x0, #(1 << 31)        // Set RW bit, routing bits 0 (async exceptions routed to NS.EL1)
  ORR      x0, x0, #(1 << 5)     // Set AMO bit
  ORR      x0, x0, #(1 << 4)     // Set FMO bit (must be set to allow vFIQ)
  ORR      x0, x0, #(1 << 3)     // Set IMO bit (must be set to allow vIRQ)
  MSR      HCR_EL2, x0

  //
  // Set up virtual interface, and register a virtual interrupt
  //

  // Initialize Active Priority registers, to show no interrupts
  MSR      ICH_AP0R0_EL2, xzr
  //MSR      ICH_AP0R1_EL2, xzr
  //MSR      ICH_AP0R2_EL2, xzr
  //MSR      ICH_AP0R3_EL2, xzr
  MSR      ICH_AP1R0_EL2, xzr
  //MSR      ICH_AP1R1_EL2, xzr
  //MSR      ICH_AP1R2_EL2, xzr
  //MSR      ICH_AP1R3_EL2, xzr

  // Initialize ICH_VMCR_EL2 (ordinarily, this would be done by the Guest)
  MOV      x0, #1                // Set VENG0
  ORR      x0, x0, #(1 << 1)     // Set VENG1
                                 // Leave VAvkCtl as 0
  ORR      x0, x0, #(1 << 3)     // Set VFIQEn
  ORR      x0, x0, #(1 << 4)     // Set VCBPR (common binary point for vG0 and vG1)
                                 // Leave VEOIM as 0
  ORR      x0, x0, #(0xFF << 24) // Set VPMR==0xFF
  MSR      ICH_VMCR_EL2, x0

  // Initialize ICH_HCR_EL2
  MOV      x0, #1                // Set En bit (virtual if enabled)
                                 // No maintenance interrupts enabled
  MSR      ICH_HCR_EL2, x0

  MSR      ICH_LR0_EL2, x0


  // Set up a list register entry to send a vIRQ
  //MOV      x0, #8197             // vINTID = 8197 (vLPI)
  //ORR      x0, x0, #(1 << 48)    // Priority = 0
  //ORR      x0, x0, #(1 << 60)    // Group = 1
                                 // HW = 0
  //ORR      x0, x0, #(0x1 << 62)  // State = b01 = Pending
  //MSR      ICH_LR0_EL2, x0

  // Intialize flag (used to detect test end)
  MOV      x11, xzr

  LDR      x0, =el1_entry_aarch64
  MSR      ELR_EL3, x0

  MOV      x0, #AArch64_EL1_SP1
  MSR      spsr_el3, x0
  ERET

// ------------------------------------------------------------
// Non-secure EL1 code
// ------------------------------------------------------------

  .section  secondary_boot_ns,"ax"
  .align 3

  //
  // NS.EL1
  //

el1_entry_aarch64:
  NOP
loop:
  WFI
  CBZ       x11, loop

  // Semihosting call to stop simulation
  MOV      w0, #0x18
  HLT      #0xf000

// ------------------------------------------------------------
// Vector Table
// ------------------------------------------------------------

  .align 12

  .global el1_vectors
el1_vectors:

// ------------------------------------------------------------
// Current EL with SP0
// ------------------------------------------------------------
  .balign 128
sync_current_el_sp0:
  B        .                    //        Synchronous

  .balign 128
irq_current_el_sp0:
  B        irqFirstLevelHandler //        IRQ

  .balign 128
fiq_current_el_sp0:
  B        fiqFirstLevelHandler //        FIQ

  .balign 128
serror_current_el_sp0:
  B        .                    //        SError

// ------------------------------------------------------------
// Current EL with SPx
// ------------------------------------------------------------

  .balign 128
sync_current_el_spx:
  B        .                    //        Synchronous

  .balign 128
irq_current_el_spx:
  B        irqFirstLevelHandler //        IRQ

  .balign 128
fiq_current_el_spx:
  B        fiqFirstLevelHandler //        FIQ

  .balign 128
serror_current_el_spx:
  B        .                    //        SError

// ------------------------------------------------------------
// Lower EL using AArch64
// ------------------------------------------------------------

  .balign 128
sync_lower_el_aarch64:
   B        .

  .balign 128
irq_lower_el_aarch64:
  B        irqFirstLevelHandler //        IRQ

  .balign 128
fiq_lower_el_aarch64:
  B        fiqFirstLevelHandler //        FIQ

  .balign 128
serror_lower_el_aarch64:
  B        .                    //        SError

// ------------------------------------------------------------
// Lower EL using AArch32
// ------------------------------------------------------------

  .balign 128
sync_lower_el_aarch32:
   B        .

  .balign 128
irq_lower_el_aarch32:
  B        irqFirstLevelHandler //        IRQ

  .balign 128
fiq_lower_el_aarch32:
  B        fiqFirstLevelHandler //        FIQ

  .balign 128
serror_lower_el_aarch32:
  B        .                    //        SError


// ------------------------------------------------------------

irqFirstLevelHandler:
  //
  // This is not a proper handler!!!
  //

  // Read IAR
  MRS      x0, ICC_IAR1_EL1     // When read from NS.EL1 with HCR_EL1.IMO==0, this will access ICV_IAR1_EL1

  LDR      x1, =irq_msg
  MOV      w0, #0x04
  HLT      #0xf000

  MSR      ICC_EOIR1_EL1, x0    // When read from NS.EL1 with HCR_EL1.IMO==0, this will access ICV_EOIR1_EL1

  ADD      x11, x11, #1        // Update flag
  ERET


fiqFirstLevelHandler:
  //
  // This is not a proper handler!!!
  //

  // Read IAR
  MRS      x0, ICC_IAR0_EL1     // When read from NS.EL1 with HCR_EL1.FIMO==0, this will access ICV_IAR0_EL1

  LDR      x1, =fiq_msg
  MOV      w0, #0x04
  HLT      #0xf000

  MSR      ICC_EOIR0_EL1, x0    // When read from NS.EL1 with HCR_EL1.FMO==0, this will access ICV_EOIR0_EL1

  ADD       x11, x11, #1        // Update flag
  ERET

//==================================================================
// Messages
//==================================================================
  .align 3

irq_msg:
  .string  "Secondary Core in IRQ handler\n\n"

fiq_msg:
  .string  "Secondary Core in FIQ handler\n\n"

// ------------------------------------------------------------
// End of file
// ------------------------------------------------------------
