// ----------------------------------------------------------
// GICv3 Functions for managing physical LPIs
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

#ifndef __gicv4_virt_h
#define __gicv4_virt_h

#include <stdint.h>

// ------------------------------------------------------------
// Address space set up
// ------------------------------------------------------------

void setSGIBaseAddr(void);

// ------------------------------------------------------------
// Discovery
// ------------------------------------------------------------

#define GICV3_v3X                        (30)
#define GICV3_v40                        (40)
#define GICV3_v41                        (41)
uint32_t isGICv4x(uint32_t rd);

// Returns 1 if vSGIs supported, 0 if vSGIs not supported
uint32_t hasVSGI(uint32_t rd);

// ------------------------------------------------------------
// Redistributor setup functions
// ------------------------------------------------------------

uint32_t setVPEConfTableAddr(uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t num_pages);

uint32_t makeResident(uint32_t rd, uint32_t vpeid, uint32_t g0, uint32_t g1);

uint32_t makeNotResident(uint32_t rd, uint32_t db);

// ------------------------------------------------------------
// Configuring LPI functions
// ------------------------------------------------------------

// Configures specified vLPI
uint32_t configureVLPI(uint8_t* table, uint32_t ID, uint32_t enable, uint32_t priority);

// ------------------------------------------------------------
// ITS setup functions
// ------------------------------------------------------------

uint32_t itsSharedTableSupport(void);

uint32_t itsGetAffinity(void);

// ------------------------------------------------------------
// vSGI
// ------------------------------------------------------------

void itsSendSGI(uint32_t vintid, uint32_t vpeid);

// ------------------------------------------------------------
// ITS commands
// ------------------------------------------------------------

void itsVMAPP(uint32_t vpeid, uint32_t target, uint64_t conf_addr, uint64_t pend_addr, uint32_t alloc, uint32_t v, uint32_t doorbell, uint32_t size);

void itsVSYNC(uint32_t vpeid);

void itsVMAPTI(uint32_t DeviceID, uint32_t EventID, uint32_t doorbell, uint32_t vpeid, uint32_t vINTID);

void itsINVDB(uint32_t vpeid);

void itsVSGI(uint32_t vpeid, uint32_t vintid, uint32_t enable, uint32_t priority, uint32_t group, uint32_t clear);

#endif

// ----------------------------------------------------------
// End of gicv4_vlpis.h
// ----------------------------------------------------------
