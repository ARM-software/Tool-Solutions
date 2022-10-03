// ------------------------------------------------------------
// ARMv8-A AArch64 Generic Timer
// Header Filer
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

#ifndef _ARMV8A_GENERIC_TIMER_H
#define _ARMV8A_GENERIC_TIMER_H

#include <stdint.h>

// ------------------------------------------------------------
// CNTFRQ holds the frequency of the system counter
// Readable in all ELs
// Writable only by EL3

// Returns the value of CNTFRQ_EL0
uint32_t getCNTFRQ(void);

// Sets the value of CNTFRQ_EL0 (EL3 only!)
// freq - The value to be written into CNTFRQ_EL3
void setCNTFRQ(uint32_t freq);

// ------------------------------------------------------------
// CNTPCT_EL0 and CNTVCT_EL0 hold the physical and virtual counts
// Always accessable in Hpy and Secure EL1
// Access from EL2 and Non-secure EL1 is configurable

// Returns the current value of physical count (CNTPCT_EL0)
uint64_t getPhysicalCount(void);

// Returns the current value of the virtual count register (CNTVCT_EL0)
uint64_t getVirtualCount(void);

// ------------------------------------------------------------
// The CNTKCTL register controls whether CNTPCT can be accessed from EL0
// Only acceable from EL1 and EL2

#define CNTKCTL_PCTEN    (1 << 0)   // Controls whether the physical counter, CNTPCT, and the frequency register CNTFRQ, are accessible from EL0
#define CNTKCTL_VCTEN    (1 << 1)   // Controls whether the virtual counter, CNTVCT, and the frequency register CNTFRQ, are accessible from
#define CNTKCTL_EVNTEN   (1 << 2)   // Enables the generation of an event stream from the virtual counter
#define CNTKCTL_EVNTDIR  (1 << 3)   // Controls which transition of the CNTVCT trigger bit, defined by EVNTI, generates an event

// Returns the value of EL1 Timer Control Register (CNTKCTL_EL1)
uint32_t getEL1Ctrl(void);

// Sets the value of EL1 Timer Control Register (CNTKCTL_EL1)
// value - The value to be written into CNTKCTL_EL1
void setEL1Ctrl(uint32_t value);

// ------------------------------------------------------------
// The CNTHCTL_EL2 register controls whether CNTPCT_EL0 can be accessed from EL1
// Only accessable from EL2 and EL3

#define CNTHCTL_CNTPCT   (1 << 0)
#define CNTHCTL_EVNTEN   (1 << 2)
#define CNTHCTL_EVNTDIR  (1 << 3)

// Returns the value of the EL2 Timer Control Register (CNTHCTL_EL2)
uint32_t getEL2Ctrl(void);

// Sets the value of EL2 Timer Control Register (CNTHCTL_EL2)
// value - The value to be written into CNTHCTL_EL2
void setEL2Ctrl(uint32_t value);

// ------------------------------------------------------------
// Non-secure Physical Timer
// ------------------------------------------------------------
// Accessible from EL3, EL2 and EL1

// Returns the value of Non-secure EL1 Physical Compare Value Register (CNTP_CVAL_EL0)
uint64_t getNSEL1PhysicalCompValue(void);

// Sets the value of the Non-secure EL1 Physical Compare Value Register (CNTP_CVAL_EL0)
// value - The value to be written into CNTP_CVAL_EL0
void setNSEL1PhysicalCompValue(uint64_t value);

// Returns the value of Non-secure EL1 Physical Timer Value Register (CNTP_TVAL_EL0)
uint32_t getNSEL1PhysicalTimerValue(void);

// Sets the value of the Non-secure EL1 Physical Timer Value Register (CNTP_TVAL_EL0)
// value - The value to be written into CNTP_TVAL_EL0
void setNSEL1PhysicalTimerValue(uint32_t value);

#define CNTP_CTL_ENABLE  (1 << 0)
#define CNTP_CTL_MASK    (1 << 1)
#define CNTP_CTL_STATUS  (1 << 2)

// Returns the value of Non-secure EL1 Physical Timer Control Register (CNTP_CTL_EL0)
uint32_t getNSEL1PhysicalTimerCtrl(void);

// Sets the value of the Non-secure EL1 Physical Timer Control Register (CNTP_CTL_EL0)
// value - The value to be written into CNTP_CTL_EL0
void setNSEL1PhysicalTimerCtrl(uint32_t value);

// ------------------------------------------------------------
// Secure Physical Timer
// ------------------------------------------------------------
// Accessible from EL3, and configurably from secure EL1

// Returns the value of Secure EL1 Physical Compare Value Register (CNTPS_CVAL_EL1)
uint64_t getSEL1PhysicalCompValue(void);

// Sets the value of the Secure EL1 Physical Compare Value Register (CNTPS_CVAL_EL1)
// value - The value to be written into CNTPS_CVAL_EL1
void setSEL1PhysicalCompValue(uint64_t value);

// Returns the value of Secure EL1 Physical Timer Value Register (CNTPS_TVAL_EL1)
uint32_t getSEL1PhysicalTimerValue(void);

// Sets the value of the Secure EL1 Physical Timer Value Register (CNTPS_TVAL_EL1)
// value - The value to be written into CNTPS_TVAL_EL1
void setSEL1PhysicalTimerValue(uint32_t value);

#define CNTPS_CTL_ENABLE  (1 << 0)
#define CNTPS_CTL_MASK    (1 << 1)
#define CNTPS_CTL_STATUS  (1 << 2)

// Returns the value of Secure EL1 Physical Timer Control Register (CNTPS_CTL_EL1)
uint32_t getSEL1PhysicalTimerCtrl(void);

// Sets the value of the Secure EL1 Physical Timer Control Register (CNTPS_CTL_EL1)
// value - The value to be written into CNTPS_CTL_EL1
void setSEL1PhysicalTimerCtrl(uint32_t value);

// The SCR_EL3 register controls whether CNTPS_TVAL_EL1,
// CNTPS_CTL_EL1, and CNTPS_CVAL_EL1 can be accessed by secure
// EL1.
// Only accessible from EL3

#define SCR_ENABLE_SECURE_EL1_ACCESS  (1)
#define SCR_DISABLE_SECURE_EL1_ACCESS (0)

// Sets the values of the SCR_EL3.ST bit (bit 11) based on the value passed in 'config'
void configSecureEL1TimerAccess(uint32_t config);

// ------------------------------------------------------------
// Virtual Timer
// ------------------------------------------------------------
// Accessible from Non-secure EL1 and EL2

//  Returns the value of EL1 Virtual Compare Value Register (CNTV_CVAL)
uint64_t getEL1VirtualCompValue(void);

// Sets the value of the EL1 Virtual Compare Value Register (CNTV_CVAL)
// value - The value to be written into CNTV_CVAL
void setEL1VirtualCompValue(uint64_t value);

// Returns the value of EL1 Virtual Timer Value Register (CNTV_TVAL)
uint32_t getEL1VirtualTimerValue(void);

// Sets the value of the EL1 Virtual Timer Value Register (CNTV_TVAL)
// value - The value to be written into CNTV_TVAL
void setEL1VirtualTimerValue(uint32_t value);

#define CNTV_CTL_ENABLE  (1 << 0)
#define CNTV_CTL_MASK    (1 << 1)
#define CNTV_CTL_STATUS  (1 << 2)

// Returns the value of EL1 Virtual Timer Control Register (CNTV_CTL)
uint32_t getEL1VirtualTimerCtrl(void);

// Sets the value of the EL1 Virtual Timer Control Register (CNTV_CTL)
// value - The value to be written into CNTV_CTL
void setEL1VirtualTimerCtrl(uint32_t value);

//
// Virtual timer functions to be called by EL2
//

// CNTVCT_EL2 holds the offset the virtual count is from the physical count
// Only accessable from EL2 and EL3

// Returns the value of the Counter Virtual Offset Register (CNTVOFF_EL2)
uint64_t getVirtualCounterOffset(void);

// Sets the value of the Counter Virtual Offset Register (CNTVOFF_EL2)
// offset - The value to be written into CNTVOFF_EL2
void setVirtualCounterOffset(uint64_t offset);

// ------------------------------------------------------------
// Hypervisor (EL2) Timer
// ------------------------------------------------------------

// Returns the value of EL2 Physical Compare Value Register (CNTHP_CVAL_EL2)
uint64_t getEL2PhysicalCompValue(void);

// Sets the value of the EL2 Physical Compare Value Register (CNTHP_CVAL_EL2)
// value - The value to be written into CNTHP_CVAL_EL2
void setEL2PhysicalCompValue(uint64_t value);

// Returns the value of EL2 Physical Timer Value Register (CNTHP_TVAL_EL2)
uint32_t getEL2PhysicalTimerValue(void);

#define CNTHP_CTL_ENABLE  (1 << 0)
#define CNTHP_CTL_MASK    (1 << 1)
#define CNTHP_CTL_STATUS  (1 << 2)

// Sets the value of the EL2 Physical Timer Value Register (CNTHP_TVAL_EL2)
// value - The value to be written into CNTHP_TVAL_EL2
void setEL2PhysicalTimerValue(uint32_t value);

#endif

// ------------------------------------------------------------
// End of generic_timer.h
// ------------------------------------------------------------
