//==================================================================
// Armv8-A Startup Code
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
//
// ------------------------------------------------------------

  .section  BOOT,"ax"
  .align 3

// ------------------------------------------------------------

  .global start64
  .type start64, @function
start64:

  // Clear registers
  // ---------------
  // This is primarily for RTL simulators, to avoid
  // possibility of X propagation
  MOV      x0, #0
  MOV      x1, #0
  MOV      x2, #0
  MOV      x3, #0
  MOV      x4, #0
  MOV      x5, #0
  MOV      x6, #0
  MOV      x7, #0
  MOV      x8, #0
  MOV      x9, #0
  MOV      x10, #0
  MOV      x11, #0
  MOV      x12, #0
  MOV      x13, #0
  MOV      x14, #0
  MOV      x15, #0
  MOV      x16, #0
  MOV      x17, #0
  MOV      x18, #0
  MOV      x19, #0
  MOV      x20, #0
  MOV      x21, #0
  MOV      x22, #0
  MOV      x23, #0
  MOV      x24, #0
  MOV      x25, #0
  MOV      x26, #0
  MOV      x27, #0
  MOV      x28, #0
  MOV      x29, #0
  MOV      x30, #0



  // Disable trapping of CPTR_EL3 accesses or use of Adv.SIMD/FPU
  // -------------------------------------------------------------
  MOV      x0, #0                           // Clear all trap bits
  MSR      CPTR_EL3, x0


  // Configure GIC CPU IF
  // -------------------
  // For processors that do not support legacy operation
  // these steps could be omitted.
  MSR      SCR_EL3, xzr                      // Ensure NS bit is clear
  ISB
  MOV      x0, #1
  MSR      ICC_SRE_EL3, x0
  ISB
  MSR      ICC_SRE_EL1, x0

  // Now do the NS SRE bits

  MOV      x1, #1                            // Set NS bit, to access Non-secure registers
  MSR      SCR_EL3, x1
  ISB
  MSR      ICC_SRE_EL2, x0
  ISB
  MSR      ICC_SRE_EL1, x0


  // Configure SCR_EL3
  // ------------------
  // Have interrupts routed to EL3
  MOV      w1, #0              // Initial value of register is unknown
  ORR      w1, w1, #(1 << 11)  // Set ST bit (Secure EL1 can access CNTPS_TVAL_EL1, CNTPS_CTL_EL1 & CNTPS_CVAL_EL1)
  ORR      w1, w1, #(1 << 10)  // Set RW bit (EL1 is AArch64, as this is the Secure world)
  ORR      w1, w1, #(1 << 3)   // Set EA bit (SError routed to EL3)
  ORR      w1, w1, #(1 << 2)   // Set FIQ bit (FIQs routed to EL3)
  ORR      w1, w1, #(1 << 1)   // Set IRQ bit (IRQs routed to EL3)
  MSR      SCR_EL3, x1

  //
  // Cortex-A35/53/57/72/73 series specific configuration
  //
  .ifdef CORTEXA
    // Configure ACTLR_EL1
    // --------------------
    // These bits are IMP DEF, so need to different for different
    // processors
    //MRS      x1, ACTLR_EL1
    //ORR      x1, x1, #1          // Enable EL1 access to ACTLR_EL1
    //ORR      x1, x1, #(1 << 1)   // Enable EL1 access to CPUECTLR_EL1
    //ORR      x1, x1, #(1 << 4)   // Enable EL1 access to L2CTLR_EL1
    //ORR      x1, x1, #(1 << 5)   // Enable EL1 access to L2ECTLR_EL1
    //ORR      x1, x1, #(1 << 6)   // Enable EL1 access to L2ACTLR_EL1
    //MSR      ACTLR_EL1, x1

    // Configure CPUECTLR_EL1
    // -----------------------
    // These bits are IMP DEF, so need to different for different
    // processors
    // SMPEN - bit 6 - Enables the processor to receive cache
    //                 and TLB maintenance operations
    //
    // NOTE: For Cortex-A57/53 CPUEN should be set before
    //       enabling the caches and MMU, or performing any cache
    //       and TLB maintenance operations.
    //MRS      x0, S3_1_c15_c2_1  // Read EL1 CPU Extended Control Register
    //ORR      x0, x0, #(1 << 6)  // Set the SMPEN bit
    //MSR      S3_1_c15_c2_1, x0  // Write EL1 CPU Extended Control Register
    //ISB
  .endif


  // Ensure changes to system register are visible
  ISB



  // Which core am I
  // ----------------
  MRS      x0, MPIDR_EL1
  MOV      x1, #0x00FFFFFF
  AND      x0, x0, x1                        // Mask off to leave Aff2.Aff1.Aff0
  CBZ      x0, primary                       // If core 0, run the primary init code
  MOV      x1, #0x00000001
  CMP      x0, x1                            // If core 1, run the secondary init code
  .global  secondary
  B.EQ     secondary
  // Otherwise go to sleep
sleep:
  WFI
  B        sleep


// ------------------------------------------------------------
// Primary core
// ------------------------------------------------------------

primary:

  // Install vector table
  // ---------------------
  .global  el3_vectors
  LDR      x0, =el3_vectors
  MSR      VBAR_EL3, x0


  // Enable Interrupts
  // ------------------
  MSR      DAIFClr, 0x3


  // Branch to scatter loading and C library init code
  // -------------------------------------------------
  .global  __main
  B        __main


// ------------------------------------------------------------
// Helper functions
// ------------------------------------------------------------

  .type getAffinity, "function"
  .cfi_startproc
  .global getAffinity
getAffinity:
  MRS      x0, MPIDR_EL1
  UBFX     x1, x0, #32, #8
  BFI      w0, w1, #24, #8
  RET
  .cfi_endproc

// ------------------------------------------------------------
// End of file
// ------------------------------------------------------------
