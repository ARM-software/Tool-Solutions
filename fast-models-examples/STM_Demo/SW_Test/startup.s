// ------------------------------------------------------------
// ARMv8-A AArch64 Startup Example
//
// Copyright Arm Ltd 2017. All rights reserved.
// ------------------------------------------------------------

  .section  BOOT,"ax"        // Define an executable ELF section, BOOT
  .align 3                   // Align to 2^3 byte boundary

  .global start64
  .type start64, "function"
start64:


  // Which core am I
  // ----------------
  MRS      x0, MPIDR_EL1
  AND      x0, x0, #0xFFFF                   // Mask off to leave Aff0 and Aff1
  CBZ      x0, boot                          // If not *.*.0.0, then go to sleep
sleep:
  WFI
  B        sleep
boot:
  

  // Disable trapping of CPTR_EL3 accesses or use of Adv.SIMD/FPU
  // -------------------------------------------------------------
  MSR      CPTR_EL3, xzr // Clear all trap bits

  // Branch to scatter loading and C library init code
  .global  __main
  B        __main


// ------------------------------------------------------------
// End of file
// ------------------------------------------------------------

