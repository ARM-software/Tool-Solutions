// ----------------------------------------------------------
// GICv3 Physical LPI functions
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
// This test has been provided by Martin Weidmann and has been extended
// to support multichip operation. The multichip operation extensions
// have taken place in gicv3_basic.h, gicv3_basic.c and gicv3_registers.h.
// This file is not tested to work with these upgrades. Append to mc_config_test.c 
// to see how multichip registers are used.
// ------------------------------------------------------------


#include <stdio.h>
#include <string.h>
#include "gicv3_lpis.h"
#include "gic_constants.h"

// The first release of ARM Compiler 6 does not support the DSB
// intrinsic.  Re-creating manually.
static __inline void __dsb(void)
{
  asm("dsb sy");
}

// Selects an ITS
// ITS_base = virtual address of ITS_base register page
void setITSBaseAddress(struct GICv3_its_ctlr_if* gic_its, struct GICv3_its_int_if* gic_its_ints, void* ITS_base)
{
  gic_its      = (struct GICv3_its_ctlr_if*)ITS_base;
  gic_its_ints = (struct GICv3_its_int_if*)(ITS_base + 0x010000);
  return;
}

// ------------------------------------------------------------
// Redistributor setup functions
// ------------------------------------------------------------

void setLPIConfigTableAddr(struct GICv3_rdist_if **gic_rdist, uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t IDbits)
{
  uint64_t tmp = 0;

  // The function takes the number of ID bits, the register expects (ID bits - 1)
  // If the number of IDbits is less than 14, then there are no LPIs
  // Also the maximum size of the EventID is 32 bit
  if ((IDbits < 14) || (IDbits > 32))
    return;  // error

  tmp = (1 << IDbits) - 8192;
  IDbits = IDbits - 1;

  // Zero table
  // This is ensure that all interrupts have a known (safe) initial config
  memset((void*)addr, 0, tmp);
  __dsb();

  // Write GICR_PROPBASER
  addr =         addr       & 0x0000FFFFFFFFF000;    // PA is bits 47:12
  tmp  = addr | (attributes & 0x0700000000000F80);   // Attributes are in bits 58:56 and 11:7
  tmp  = tmp  | (IDbits     & 0x000000000000001F);   // IDBits is bits 4:0
  (*gic_rdist)[rd].lpis.GICR_PROPBASER = tmp;

  return;
}

// ------------------------------------------------------------

// Set address of the LPI pending table for the currently selected Redistributor
// addr       = physical address of allocated memory
// attributes = cacheability/shareabilty settings
// IDbits     = number of ID bits (needed in order to work how much memory to zero)
//
// NOTE: The amount of memory allocated must be enough for the number of IDbits!
void setLPIPendingTableAddr(struct GICv3_rdist_if **gic_rdist, uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t IDbits)
{
  uint64_t tmp = 0;

  // The function takes the number of ID bits, the register expects (ID bits - 1)
  // If the number of IDbits is less than 14, then there are no LPIs
  if ((IDbits < 14) || (IDbits > 32))
    return;  // error

  // Zero table
  // This is ensure that all interrupts have a known (inactive) initial state
  // TBD: Fix memset to only clear required bytes!
  tmp = 1 << IDbits;
  memset((void*)addr, 0, tmp);
  __dsb();

  // Write GICR_PENDBASER
  addr =         addr       & 0x0000FFFFFFFF0000;    // PA is bits 47:16
  tmp  = addr | (attributes & 0x0700000000000F80);   // Attributes are in bits 58:56 and 11:7
  (*gic_rdist)[rd].lpis.GICR_PENDBASER = tmp;

  return;
}

// ------------------------------------------------------------

// Enables LPIs for the currently selected Redistributor
void enableLPIatRD(struct GICv3_rdist_if **gic_rdist, uint32_t rd)
{
   (*gic_rdist)[rd].lpis.GICR_CTLR = ((*gic_rdist)[rd].lpis.GICR_CTLR | 0x1);
  __dsb();
  return;
}

// ------------------------------------------------------------

uint32_t getRdProcNumber(struct GICv3_rdist_if **gic_rdist, uint32_t rd)
{

  return (((*gic_rdist)[rd].lpis.GICR_TYPER[0] >> 8) & 0xFFFF);
}

// ------------------------------------------------------------

void sendLPI(struct GICv3_rdist_if **gic_rdist, uint32_t rd, uint32_t ID)
{
  (*gic_rdist)[rd].lpis.GICR_SETLPIR = (uint64_t)ID;
  return;
}


// ------------------------------------------------------------
// Configuring LPI functions
// ------------------------------------------------------------

// Configures specified LPI
// ID       = ID of LPI to be configured (must be 8192 or greater, no upper limit check)
// enable   = whether ID is enabled (1=enabled, 0=disabled)
// priority = priority for ID
void configureLPI(struct GICv3_rdist_if **gic_rdist, uint32_t rd, uint32_t ID, uint32_t enable, uint32_t priority)
{
  uint8_t* config;

  // LPIs use the IDs 8192 to IMP DEF limit

  // Check lower limit
  if (ID < 8192)
    return;

  // Check upper limit
  // TBD

  // Set up a pointer to the configuration table
  config = (uint8_t*)((*gic_rdist)[rd].lpis.GICR_PROPBASER & 0x0000FFFFFFFFF000);

  // Mask off unused bits of the priority and enable
  enable = enable & 0x1;
  priority = priority & 0x7C;

  // Combine priority and enable, write result into table
  // Note: bit 1 is RES1
  config[(ID - 8192)] = (0x2 | enable | priority);
  __dsb();

  // Perform invalidation
  // How invalidation is performed depends on whether an ITS is present.
  // Where there is no ITS it is performed using registers in the
  // Redistributors.  Where an ITS is present, an INV command is needed.
  // Can't include this here, as it requires the EventID and DeviceID.
  #ifdef DIRECT
  (*gic_rdist)[rd].lpis.GICR_INVLPIR = ID;

  while ((*gic_rdist)[rd].lpis.GICR_SYNCR != 0)
  {}
  #endif

  return;
}

void initLPITable(struct GICv3_rdist_if **gic_rdist,  uint32_t rd,
                  uint64_t config_table_addr,  uint64_t config_table_attr,  uint32_t config_table_IDbits,
                  uint64_t pending_table_addr, uint64_t pending_table_attr, uint32_t pending_table_IDbits)
{
  setLPIConfigTableAddr(gic_rdist,  rd, config_table_addr,  config_table_attr,  config_table_IDbits);
  setLPIPendingTableAddr(gic_rdist, rd, pending_table_addr, pending_table_attr, pending_table_IDbits);
  enableLPIatRD(gic_rdist, rd);
}

// ------------------------------------------------------------
// ITS setup functions
// ------------------------------------------------------------

// Initializes the currently selected ITS's command queue
// addr       = base address of allocated memory, must be 64K aligned
// attributes = cacheabilit, shareabilty and valid bit
// num_pages  = number of 4K pages (must be 1 or greater)
//
// NOTE: The GITS_CBASER encodes the number of pages as (number - 1).
// This functions expects an unmodified value (i.e. pass 1, if 1 page allocated).
void initITSCommandQueue(struct GICv3_its_ctlr_if* gic_its, uint64_t addr, uint64_t attributes, uint64_t num_pages)
{
  uint64_t tmp;

  addr       = addr       & (uint64_t)0x0000FFFFFFFFF000;
  attributes = attributes & (uint64_t)0xF800000000000C00;
  num_pages  = num_pages  & 0x00000000000000FF;

  // check number of pages is not 0
  if (num_pages == 0)
    return;  // error

  // TBD: Add check for sane number of pages

  // work out queue size in bytes, then zero memory
  // This code assumes that VA=PA for allocated memory
  tmp = num_pages * 4096;
  memset((void*)addr, 0, tmp);

  // Combine address, attributes and size
  tmp = addr | attributes | (num_pages - 1);

  gic_its->GITS_CBASER  = tmp;
  gic_its->GITS_CWRITER = 0;    // This register contains the offset from the start, hence setting to 0

  // TBD: add a barrier here

  return;
}

// ------------------------------------------------------------

// Returns the type and entry size of GITS_BASER[index] of the currently selected ITS
// index = which GITS_BASERn register to access, must be in the range 0 to 7
// type  = pointer to a uint32_t, function write the vale of the GITS_BASERn.Type to this pointer
// entry_size  = pointer to a uint32_t, function write the vale of the GITS_BASERn.Entry_Size to this pointer
uint64_t getITSTableType(struct GICv3_its_ctlr_if* gic_its, uint32_t index, uint32_t* type, uint32_t* entry_size)
{
  // Range check (there are only 8 (0-7) registers)
  if (index > 7)
    return 0;  // error

  *type       = (uint32_t)(0x7  & (gic_its->GITS_BASER[index] >> 56));
  *entry_size = (uint32_t)(0x1F & (gic_its->GITS_BASER[index] >> 48));

  return 1;
}

// ------------------------------------------------------------

// Sets GITS_BASER[entry]
// index = which GITS_BASERn register to access, must be in the range 0 to 7
// addr  = phsyical address of allocated memory.  Must be at least 4K aligned.
// attributes = Cacheability, shareabilty, validity and indirect settings
// page_size  = Size of allocated pages (4K=0x0, 16K=0x100, 64K=0x200)
// num_pages  = The number of allocated pages.  Must be greater than 0.
//
// NOTE: The registers encodes as (number - 1), this function expecst then
// actual number
void setITSTableAddr(struct GICv3_its_ctlr_if* gic_its, uint32_t index, uint64_t addr, uint64_t attributes, uint32_t page_size, uint32_t num_pages)
{
  uint64_t tmp;

  // Range check:
  // - there are only 8 (0-7) registers (In case of GICv4, there will be upto 3 tables)
  // - code doesn't allow for 0 pages (minimum that can be encoded into the register is 1)
  if ((index > 7) || (num_pages == 0))
    return;  // error


  // Combine fields to form entery
  tmp = (num_pages - 1) & 0xFF;
  tmp = tmp | (page_size  & 0x300);
  tmp = tmp | (addr       & (uint64_t)0x0000FFFFFFFFF000);
  tmp = tmp | (attributes & (uint64_t)0xF800000000000C00);

  gic_its->GITS_BASER[index] = tmp;


  // Zero memory
  // work out queue size in bytes, then zero memory
  // This code assumes that VA=PA for allocated memory
  if (page_size == GICV3_ITS_TABLE_PAGE_SIZE_4K)
    tmp = 0x1000 * num_pages;
  else if (page_size == GICV3_ITS_TABLE_PAGE_SIZE_16K)
    tmp = 0x4000 * num_pages;
  else if (page_size == GICV3_ITS_TABLE_PAGE_SIZE_64K)
    tmp = 0x10000 * num_pages;

  memset((void*)addr, 0, tmp);

  return;
}

// ------------------------------------------------------------

// Returns the value of GITS_TYPER.PTA bit (shifted down to LSB)
uint32_t getITSPTA(struct GICv3_its_ctlr_if* gic_its)
{
  return ((gic_its->GITS_TYPER >> 19) & 1);
}

// ------------------------------------------------------------

// Sets the GITS_CTLR.Enabled bit
void enableITS(struct GICv3_its_ctlr_if* gic_its)
{
  gic_its->GITS_CTLR = 1;
  return;
}

// ------------------------------------------------------------

// Clears the GITS_CTLR.Enabled bit
void disableITS(struct GICv3_its_ctlr_if* gic_its)
{
  gic_its->GITS_CTLR = 0;
  return;
}

// ------------------------------------------------------------
// ITS commands
// ------------------------------------------------------------

#define COMMAND_SIZE  (32)
// Adds a command to the currently selected ITS's queue.
// command = pointer to 32 bytes of memory containing a ITS command
//
// NOTE: This function is intended for internal use only.
void itsAddCommand(struct GICv3_its_ctlr_if* gic_its, uint8_t* command)
{
  uint32_t i, queue_size;
  uint64_t new_cwriter, queue_base, queue_offset, queue_read;
  uint8_t* entry;


  queue_size = ((gic_its->GITS_CBASER & 0xFF) + 1) * 0x1000;  // GITS_CBASER.Size returns the number of 4K pages, minus -1
  queue_base = (gic_its->GITS_CBASER & (uint64_t)0x0000FFFFFFFFF000);
  queue_offset = gic_its->GITS_CWRITER;                       // GITS_CWRITER contains the offset
  queue_read   = gic_its->GITS_CREADR;

  // Check that the queue is not full
  // The queue is full when GITS_CWRITER points at
  // the entry before GITS_CREADR. To make the check
  // simpler I've moved the GITS_CREADR down one entry.
  if (queue_read == 0)
    queue_read = queue_size - COMMAND_SIZE;
  else
    queue_read = queue_read - COMMAND_SIZE;

  // Wait until queue not full
  // In practice it should very rarely be full
  while (queue_offset == queue_read)
  {}


  // Get the address of the next (base + write offset)
  entry = (uint8_t*)(queue_base + queue_offset);

  // Copy command into queue
  for(i=0; i<32; i++)
    entry[i] = command[i];

  __dsb();

  // Move on queue
  new_cwriter = queue_offset + COMMAND_SIZE;

  // Check for roll-over
  if (new_cwriter == queue_size)
    new_cwriter = 0;

  // Update GITS_CWRITER, which also tells the ITS there is a new command
  gic_its->GITS_CWRITER = new_cwriter;
  
  // Poll for read pointer to move on (consuming command)
  //
  // This driver is cautious, and waits for commands to be consumed
  // before returning.  It could have been less cautious, and
  // required software to issue an INT to detect completion.
  while(gic_its->GITS_CWRITER != gic_its->GITS_CREADR)
  {}

  return;
}

// ------------------------------------------------------------

// Issues a MAPD command to the currently selected ITS
// device = The device id
// table  = Physical address (must be in Non-secure PA space)
// of the ITT table to be used
// size   = The number of bits of ID used by the device
//
// NOTE: The underlying command records the size as (number - 1).
// This functions expects an unmodified value (i.e. pass 2, if 2 bits).
void itsMAPD(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint64_t table, uint32_t size)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // The command takes "actual_size - 1", the function takes
  // actual_size.  Therefore need to subtract one.
  if (size > 0)
    size--;
  else
    return; // error

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_MAPD);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1,  4,  0, size);
  insertCommandField(command, 2, 51,  8, table >> 8);
  insertCommandField(command, 2, 63, 63, 1); // Valid bit

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a MAPC command to the currently selected ITS
// target     = the target Redistributor.  Either the PA or the ID, depending on GITS_TYPER
// collection = the collection id
void itsMAPC(struct GICv3_its_ctlr_if* gic_its, uint32_t target, uint32_t collection)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);
    
  // Check whether "target" is PA or Processor Number
  if (getITSPTA(gic_its))
     target = target >> 16;

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_MAPC);
  insertCommandField(command, 2, 15,  0, collection);
  insertCommandField(command, 2, 50, 16, target);
  insertCommandField(command, 2, 63, 63, 1); // Valid bit

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a MAPI command to the currently selected ITS
// device_id= the DeviceID
// event_id = the EventID (the "ID" the peripheral will write)
// cid      = the collection id
void itsMAPI(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id, uint16_t cid)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_MAPI);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);
  insertCommandField(command, 2, 15,  0, cid);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);
}

// ------------------------------------------------------------

// Issues a MAPTI command to the currently selected ITS
// device   = the device ID
// event_id = the event id (the "ID" the peripheral will write)
// intid    = the GIC INTID (the "ID" that will be reported when readin IAR)
// cid      = the collection id
void itsMAPTI(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id, uint32_t intid, uint32_t cid)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_MAPTI);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);
  insertCommandField(command, 1, 63, 32, intid);
  insertCommandField(command, 2, 15,  0, cid);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues an INVALL command to the currently selected ITS
// cid      = the collection id
void itsINVALL(struct GICv3_its_ctlr_if* gic_its, uint32_t cid)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_INVALL);
  insertCommandField(command, 2, 15,  0, cid);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues an INV command to the currently selected ITS
// device_id = the DeviceID
// event_id  = the EventID
void itsINV(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_INV);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a SYNC command to the currently selected ITS
// target = The target Redistributor.  Either the PA or the ID, depending on GITS_TYPER
void itsSYNC(struct GICv3_its_ctlr_if* gic_its, uint64_t target)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  if (getITSPTA(gic_its))
    target = target >> 16;

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_SYNC);
  insertCommandField(command, 2, 50, 16, target);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a INT command to the currently selected ITS
// device = device id
// id     = event id  (the value the peripheral would have written)
void itsINT(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_INT);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a CLR command to the currently selected ITS
// device_id = the DeviceID
// event_id  = EventID
void itsCLR(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_CLEAR);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a DISCARD command to the currently selected ITS
// device_id = the DeviceID
// event_id  = EventID
void itsDISCARD(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_DISCARD);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a MOVI command to the currently selected ITS
// device_id = the DeviceID
// event_id  = EventID
// cid       = the collection id
void itsMOVI(struct GICv3_its_ctlr_if* gic_its, uint32_t device_id, uint32_t event_id, uint16_t cid)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_MOVI);
  insertCommandField(command, 0, 63, 32, device_id);
  insertCommandField(command, 1, 31,  0, event_id);
  insertCommandField(command, 2, 15,  0, cid);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

// ------------------------------------------------------------

// Issues a MOVALL command to the currently selected ITS
// source_rd = the source redistributor
// target_rd = the target redistributor
void itsMOVALL(struct GICv3_its_ctlr_if* gic_its, uint64_t source_rd, uint64_t target_rd)
{
  uint64_t command[ITS_CMD_SIZE_IN_LONG_WORDS];
  uint8_t* command_bytes = (uint8_t*)command;

  // Fill command with 0s
  memset(command_bytes, 0, ITS_CMD_SIZE_IN_BYTES);

  if (getITSPTA(gic_its))
  {
    source_rd = source_rd >> 16;
    target_rd = target_rd >> 16;
  }

  // Construct command
  insertCommandField(command, 0,  7,  0, ITS_CMD_MOVALL);
  insertCommandField(command, 2, 50, 16, source_rd);
  insertCommandField(command, 3, 50, 16, target_rd);

  // Add command to queue
  itsAddCommand(gic_its, command_bytes);

  return;
}

/// Command construction helpers

// Returns a 64-bit mask between bit offsets s and e. e.g: mask64(9,4) returns 0x00000000_000003f0
uint64_t mask64(uint8_t s, uint8_t e)
{
    return (   (UINT64_C(0xffffffffffffffff) >> (UINT8_C(63) - (s)))
             & (UINT64_C(0xffffffffffffffff) << (e)) );
}

// Inserts a value into the bits msb to lsb of the data-word dw64 of command.
void insertCommandField(uint64_t* cmd, uint8_t dw64, uint8_t msb, uint8_t lsb, uint64_t value64)
{
    cmd[dw64] = (cmd[dw64] &~ (uint64_t)mask64(msb, lsb)) | ((value64<<lsb) & (uint64_t)mask64(msb,lsb));
}

// Returns the value that exists between the bits msb to lsb of the data-word dw64 of command.
uint64_t getCommandField(uint64_t* cmd, uint8_t dw64, uint8_t s, uint8_t e)
{
    return ( cmd[dw64] & mask64(s,e) ) >> e;
}

// ------------------------------------------------------------
// End of giv3_lpis.c
// ------------------------------------------------------------
