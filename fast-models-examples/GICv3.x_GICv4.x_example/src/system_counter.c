// ----------------------------------------------------------
// System Counter
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


#include "system_counter.h"

struct memory_mapped_timer_module
{
        volatile uint32_t CNTCR;                  // +0x0000 - RW - Counter Control Register
  const volatile uint32_t CNTSR;                  // +0x0004 - RO - Counter Status Register
        volatile uint64_t CNTCV;                  // +0x0008 - RW - Counter Count Value register
        volatile uint32_t CNTSCR;                 // +0x0010 - RW - Counter Scaling Value (ARMv8.4-CNTSC)
  const volatile uint32_t padding0[2];            // +0x0014 - RESERVED
  const volatile uint32_t CNTID;                  // +0x001C - RO - Counter ID register
        volatile uint32_t CNTFID[4];              // +0x0020 - RW - Counter Access Control Register N
};

// ------------------------------------------------------------
// Setting location of interfaces
// ------------------------------------------------------------


struct memory_mapped_timer_module*    counter_module;

// Sets the address of memory mapped counter module
// addr - virtual address of counter module
void setSystemCounterBaseAddr(uint64_t addr)
{
  counter_module = (struct memory_mapped_timer_module*)addr;
  return;
}

// ------------------------------------------------------------
// Functions
// ------------------------------------------------------------

// Configures and enables the CNTCR (Counter Control Register)
// hdbg   - halt on debug mode
// freq   - frequency mode
void initSystemCounter( uint32_t hdbg, uint32_t freq, uint32_t scaling)
{
  counter_module->CNTCR = (0x1 | ((0x1 & hdbg) << 1) | ((0x1 & scaling) << 2) | ((0x3FF & freq) << 8));
  return;
}

// Set the scaling factor (CNTSCR)
// scale - Scaling factor (32-bit fixed point value, 8-bit integer with 24-bit fractional)
// Returns 0 if successful
//         1 if counter enabled (writing CNTSCR is UNPRED when counter enabled)
//         2 if feature not supported
uint32_t setSystemCounterScalingFactor(uint32_t scale)
{
  if ((counter_module->CNTCR & 0x1) == 0x1)
     return 1;  // Counter running, cannot set scaling factor

  if ((counter_module->CNTID & 0xF) == 0x0)
     return 2;  // Scaling factor

  counter_module->CNTSCR = scale;
  return 0;
}


// Returns the value of CNTID (Counter ID register)
uint32_t getCNTID(void)
{
  return counter_module->CNTID;
}


// Returns the value of the CNTSR
// Can be used to frequency changes (via init function) have taken effect
uint32_t getCNTSR(void)
{
  return (counter_module->CNTSR);
}


// Returns the value of CNTCV (Counter Count Value register)
uint64_t getCNTCV(void)
{
  return (counter_module->CNTCV);
}


// Sets the value of CNTCV (Counter Count Value register)
// value - Sets the count value
//
// NOTE: This should only be called when the counter is disabled.
// Calling while counter enabled is UNPREDICTABLE.
void setCNTCV(uint64_t value)
{
  counter_module->CNTCV = value;
  return;
}


uint32_t getCNTFID(uint32_t entry)
{
  return (counter_module->CNTFID[entry]);
}


void setCNTFID(uint32_t entry, uint32_t value)
{
  counter_module->CNTFID[entry] = value;
  return;
}


// ------------------------------------------------------------
// End of system_counter.c
// ------------------------------------------------------------
