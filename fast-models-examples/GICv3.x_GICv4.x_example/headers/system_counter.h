// ----------------------------------------------------------
// System counter
// Header
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


#ifndef __memory_mapped_timer_h
#define __memory_mapped_timer_h

#include <stdint.h>

// Sets the address of memory mapped counter module
// addr - virtual address of counter module
void setSystemCounterBaseAddr(uint64_t addr);

#define SYSTEM_COUNTER_CNTCR_HDBG     (1)
#define SYSTEM_COUNTER_CNTCR_nHDBG    (0)

#define SYSTEM_COUNTER_CNTCR_SCALE    (1)
#define SYSTEM_COUNTER_CNTCR_nSCALE   (0)

#define SYSTEM_COUNTER_CNTCR_FREQ0    (0)
#define SYSTEM_COUNTER_CNTCR_FREQ1    (1)
#define SYSTEM_COUNTER_CNTCR_FREQ2    (2)

// Configures and enables the CNTCR (Counter Control Register)
// hdbg   - halt on debug mode
// freq   - frequency mode
void initSystemCounter(uint32_t hdbg, uint32_t freq, uint32_t scaling);


// Set the scaling factor (CNTSCR)
// scale - Scaling factor (32-bit fixed point value, 8-bit integer with 24-bit fractional)
// Returns 0 if successful
//         1 if counter enabled (writing CNTSCR is UNPRED when counter enabled)
//         2 if feature not supported
uint32_t setSystemCounterScalingFactor(uint32_t scale);


// Returns the value of CNTID (Counter ID register)
uint32_t getCNTID(void);


// Returns the value of the CNTSR
uint32_t getCNTSR(void);


// Returns the value of CNTCV (Counter Count Value register)
uint64_t getCNTCV(void);


// Sets the value of CNTCV (Counter Count Value register)
// value - Sets the count value
//
// NOTE: This should only be called when the counter is disabled.
// Calling while counter enabled is UNPREDICTABLE.
void setCNTCV(uint64_t value);


// Returns the value of the specified CNTFIDn register
// entry - 
uint32_t getCNTFID(uint32_t entry);

// Set the specified CNTFIDn register
// entry - 
// value - 
void setCNTFID(uint32_t entry, uint32_t value);

#endif

// ----------------------------------------------------------
// End of system_counter.h
// ----------------------------------------------------------
