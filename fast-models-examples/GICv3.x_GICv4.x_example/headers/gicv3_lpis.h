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

#ifndef __gicv3_lpis_h
#define __gicv3_lpis_h

#include <stdint.h>

// ------------------------------------------------------------
// Address Functions
// ------------------------------------------------------------

// Selects an ITS
// ITS_base = virtual address of ITS_base register page
void setITSBaseAddress(void* ITS_base);

// ------------------------------------------------------------
// Redistributor setup functions
// ------------------------------------------------------------

// Used for setLPIConfigTableAddr() and setLPIPendingTableAddr()
#define GICV3_LPI_INNER_SHARED  (0x1 << 10)
#define GICV3_LPI_OUTER_SHARED  (0x2 << 10)
#define GICV3_LPI_NON_SHARED    (0)

#define GICV3_LPI_NORMAL_WBWA   (((uint64_t)0x5 << 56) | (uint64_t)(0x5 << 7))
#define GICV3_LPI_DEVICE_nGnRnE (0)


// Set address of LPI config table for the selected Redistributor
// rd         = Redistributor
// addr       = physical address of allocated memory
// attributes = cacheability/shareabilty settings
// IDbits     = number of ID bits
//
// NOTE: If IDbits > GICD_TYPER.IDbits, GICD_CTLR.IDbits will be used
// NOTE: The amount of memory allocated must be enough for the number of IDbits!
// NOTE: This function will use memset() to zero the allocated memory.
uint32_t setLPIConfigTableAddr(uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t INTIDbits);


// Set address of the LPI pending table for the selected Redistributor
// rd         = Redistributor
// addr       = physical address of allocated memory
// attributes = cacheability/shareabilty settings
// IDbits     = number of ID bits (needed in order to work how much memory to zero)
//
// NOTE: The amount of memory allocated must be enough for the number of IDbits!
// NOTE: This function will use memset() to zero the allocated memory.
uint32_t setLPIPendingTableAddr(uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t INTIDbits);


// Enables LPIs for the currently selected Redistributor
// NOTE: DO NOT CALL THIS BEFORE ALLOCATING TABLES!
void enableLPIs(uint32_t rd);


// Returns the RD's Processor_Number, used in ITS commands when GITS_TYPER.PTA==0
uint32_t getRdProcNumber(uint32_t rd);


// Returns the maximum LPI INTID supported by the GIC
uint32_t getMaxLPI(uint32_t rd);

// ------------------------------------------------------------
// Configuring LPI functions
// ------------------------------------------------------------

#define GICV3_LPI_ENABLE                 (1)
#define GICV3_LPI_DISABLE                (0)

// Configures specified LPI
// rd       = Redistributor
// INTID    = INTID of LPI to be configured (must be 8192 or greater, no upper limit check)
// enable   = whether ID is enabled (1=enabled, 0=disabled)
// priority = priority for ID
uint32_t configureLPI(uint32_t rd, uint32_t INTID, uint32_t enable, uint32_t priority);


// ------------------------------------------------------------
// ITS setup functions
// ------------------------------------------------------------

#define GICV3_ITS_CQUEUE_VALID          ((uint64_t)1 << 63)
#define GICV3_ITS_CQUEUE_INVALID        (0)

// Initializes the currently selected ITS's command queue
// addr       = base address of allocated memory, must be 64K aligned
// attributes = cacheabilit, shareabilty and valid bit
// num_pages  = number of 4K pages (must be 1 or greater)
//
// NOTE: The GITS_CBASER encodes the number of pages as (number - 1).
// This functions expects an unmodified value (i.e. pass 1, if 1 page allocated).
// NOTE: This function will use memset() to zero the allocated memory.
uint32_t initITSCommandQueue(uint64_t addr, uint64_t attributes, uint32_t num_pages);

// Returns the type and entry size of GITS_BASER[index] of the currently selected ITS
// index = which GITS_BASERn register to access, must be in the range 0 to 7
// type  = pointer to a uint32_t, function write the vale of the GITS_BASERn.Type to this pointer
// entry_size  = pointer to a uint32_t, function write the vale of the GITS_BASERn.Entry_Size to this pointer

#define GICV3_ITS_TABLE_TYPE_UNIMPLEMENTED (0x0)
#define GICV3_ITS_TABLE_TYPE_DEVICE        (0x1)
#define GICV3_ITS_TABLE_TYPE_VIRTUAL       (0x2)
#define GICV3_ITS_TABLE_TYPE_COLLECTION    (0x4)

#define GICV3_ITS_TABLE_PAGE_SIZE_4K       (0x0)
#define GICV3_ITS_TABLE_PAGE_SIZE_16K      (0x1)
#define GICV3_ITS_TABLE_PAGE_SIZE_64K      (0x2)

uint64_t getITSTableType(uint32_t index, uint32_t* type, uint32_t* entry_size);


// Sets GITS_BASER[entry]
// index = which GITS_BASERn register to access, must be in the range 0 to 7
// addr  = phsyical address of allocated memory.  Must be at least 4K aligned.
// attributes = Cacheability, shareabilty, validity and indirect settings
// page_size  = Size of allocated pages (4K=0x0, 16K=0x100, 64K=0x200)
// num_pages  = The number of allocated pages.  Must be greater than 0.
//
// NOTE: The registers encodes as (number - 1), this function expecst then
// actual number

#define GICV3_ITS_TABLE_PAGE_VALID            ((uint64_t)1 << 63)
#define GICV3_ITS_TABLE_PAGE_INVALID          (0)

#define GICV3_ITS_TABLE_PAGE_DIRECT           (0)
#define GICV3_ITS_TABLE_PAGE_INDIRECT         (1 << 62)

#define GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE    (0)
#define GICV3_ITS_TABLE_PAGE_NORM_WBWA        (((uint64_t)0x5 << 59) | ((uint64_t)0x5 << 53))

#define GICV3_ITS_TABLE_INNER_SHAREABLE       (0x1 << 10)
#define GICV3_ITS_TABLE_OUTER_SHAREABLE       (0x2 << 10)
#define GICV3_ITS_TABLE_NON_SHAREABLE         (0)

uint32_t setITSTableAddr(uint32_t index, uint64_t addr, uint64_t attributes, uint32_t page_size, uint32_t num_pages);


// Returns the value of GITS_TYPER.PTA bit (shifted down to LSB)

#define GICV3_ITS_PTA_ADDRESS              (1)
#define GICV3_ITS_PTA_ID                   (0)

uint32_t getITSPTA(void);


// Sets the GITS_CTLR.Enabled bit
void enableITS(void);


// Clears the GITS_CTLR.Enabled bit
void disableITS(void);


// ------------------------------------------------------------
// ITS commands
// ------------------------------------------------------------

// Issues a MAPD command to the currently selected ITS
// device = The device id
// table  = Physical address of the ITT table to be used
// size   = The number of bits of ID used by the device
//
// NOTE: The underlying command records the size as (number - 1).
// This functions expects an unmodified value (i.e. pass 2, if 2 bits).
void itsMAPD(uint32_t device_id, uint64_t table, uint32_t size);


// Issues a MAPC command to the currently selected ITS
// target     = the target Redistributor.  Either the PA or the ID, depending on GITS_TYPER
// collection = the collection id
void itsMAPC(uint32_t target, uint32_t collection);


// Issues a MAPTI command to the currently selected ITS
// device_id= the DeviceID
// event_id = the EventID (the "ID" the peripheral will write)
// intid    = the GIC INTID (the "ID" that will be reported when readin IAR)
// cid      = the collection id
void itsMAPTI(uint32_t device_id, uint32_t event_id, uint32_t intid, uint32_t cid);


// Issues an INVALL command to the currently selected ITS
// cid      = the collection id
void itsINVALL(uint32_t cid);


// Issues an INV command to the currently selected ITS
// device_id = the DeviceID
// event_id  = the EventID
void itsINV(uint32_t device_id, uint32_t event_id);


// Issues a SYNC command to the currently selected ITS
// target = The target Redistributor.  Either the PA or the ID, depending on GITS_TYPER
void itsSYNC(uint64_t target);


// Issues a INT command to the currently selected ITS
// device = device id
// id     = EventID  (the value the peripheral would have written)
void itsINT(uint32_t device, uint32_t event_id);

#endif

// ----------------------------------------------------------
// End of armv8_aarch64_gicv3.h
// ----------------------------------------------------------
