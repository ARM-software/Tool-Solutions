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
// is provided "as is", without warranty of any kind, express or implied. In no
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

void setSGIBaseAddr(struct GICv3_its_ctlr_if* gic_its, struct GICv3_its_sgi_if* gic_its_sgi);

// ------------------------------------------------------------
// Discovery
// ------------------------------------------------------------

#define GICV3_v3X                        (30)
#define GICV3_v40                        (40)
#define GICV3_v41                        (41)
uint32_t isGICv4x(struct GICv3_rdist_if* gic_rdist, uint32_t rd);

// Returns 1 if vSGIs supported, 0 if vSGIs not supported
uint32_t hasVSGI(struct GICv3_its_ctlr_if* gic_its, struct GICv3_rdist_if* gic_rdist, uint32_t rd);

// ------------------------------------------------------------
// Redistributor setup functions
// ------------------------------------------------------------

uint32_t setVPEConfTableAddr(struct GICv3_rdist_if* gic_rdist, uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t num_pages);

uint32_t makeResident(struct GICv3_rdist_if* gic_rdist, uint32_t rd, uint32_t vpeid, uint32_t g0, uint32_t g1);

uint32_t makeNotResident(struct GICv3_rdist_if* gic_rdist, uint32_t rd, uint32_t db);

// ------------------------------------------------------------
// Configuring LPI functions
// ------------------------------------------------------------

// Configures specified vLPI
void configureVLPI(uint8_t* table, uint32_t ID, uint32_t enable, uint32_t priority);

// ------------------------------------------------------------
// ITS setup functions
// ------------------------------------------------------------

uint32_t itsSharedTableSupport(struct GICv3_its_ctlr_if* gic_its);

uint32_t itsGetAffinity(struct GICv3_its_ctlr_if* gic_its);

// ------------------------------------------------------------
// vSGI
// ------------------------------------------------------------

void itsSendSGI(struct GICv3_its_sgi_if* gic_its_sgi, uint32_t vintid, uint32_t vpeid);

// ------------------------------------------------------------
// ITS commands
// ------------------------------------------------------------

void itsVMAPP(struct GICv3_its_ctlr_if* gic_its, uint32_t vpeid, uint32_t target, uint64_t conf_addr, uint64_t pend_addr, uint32_t alloc, uint32_t v, uint32_t doorbell, uint32_t size);

void itsVSYNC(struct GICv3_its_ctlr_if* gic_its, uint32_t vpeid);

void itsVMAPTI(struct GICv3_its_ctlr_if* gic_its, uint32_t DeviceID, uint32_t EventID, uint32_t doorbell, uint32_t vpeid, uint32_t vINTID);

void itsINVDB(struct GICv3_its_ctlr_if* gic_its, uint32_t vpeid);

void itsVSGI(struct GICv3_its_ctlr_if* gic_its, uint32_t vpeid, uint32_t vintid, uint32_t enable, uint32_t priority, uint32_t group, uint32_t clear);

#endif

// ----------------------------------------------------------
// End of gicv4_vlpis.h
// ----------------------------------------------------------
