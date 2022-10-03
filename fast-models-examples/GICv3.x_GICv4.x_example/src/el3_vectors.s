// ------------------------------------------------------------
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
// is provided “as is”, without warranty of any kind, express or implied. In no
// event shall the authors or copyright holders be liable for any claim, damages
// or other liability, whether in action or contract, tort or otherwise, arising
// from, out of or in connection with the Software or the use of Software.
//
// ------------------------------------------------------------

  .section  VECTORS,"ax"
  .align 12


  .global el3_vectors
el3_vectors:

  .global fiqHandler

// ------------------------------------------------------------
// Current EL with SP0
// ------------------------------------------------------------
	.balign 128
sync_current_el_sp0:
  B        .                    //        Synchronous

	.balign 128
irq_current_el_sp0:
  B        .                    //        IRQ

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
  B        .                    //        IRQ

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
  B        .                    //        IRQ

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
  B        .                    //        IRQ

	.balign 128
fiq_lower_el_aarch32:
  B        fiqFirstLevelHandler //        FIQ

	.balign 128
serror_lower_el_aarch32:
  B        .                    //        SError


// ------------------------------------------------------------

fiqFirstLevelHandler:
  STP      x29, x30, [sp, #-16]!
  STP      x18, x19, [sp, #-16]!
  STP      x16, x17, [sp, #-16]!
  STP      x14, x15, [sp, #-16]!
  STP      x12, x13, [sp, #-16]!
  STP      x10, x11, [sp, #-16]!
  STP      x8, x9, [sp, #-16]!
  STP      x6, x7, [sp, #-16]!
  STP      x4, x5, [sp, #-16]!
  STP      x2, x3, [sp, #-16]!
  STP      x0, x1, [sp, #-16]!

  BL       fiqHandler

  LDP      x0, x1, [sp], #16
  LDP      x2, x3, [sp], #16
  LDP      x4, x5, [sp], #16
  LDP      x6, x7, [sp], #16
  LDP      x8, x9, [sp], #16
  LDP      x10, x11, [sp], #16
  LDP      x12, x13, [sp], #16
  LDP      x14, x15, [sp], #16
  LDP      x16, x17, [sp], #16
  LDP      x18, x19, [sp], #16
  LDP      x29, x30, [sp], #16
  ERET

// ------------------------------------------------------------
// End of file
// ------------------------------------------------------------

