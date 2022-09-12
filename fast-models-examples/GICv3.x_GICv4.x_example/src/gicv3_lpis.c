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
// is provided “as is”, without warranty of any kind, express or implied. In no
// event shall the authors or copyright holders be liable for any claim, damages
// or other liability, whether in action or contract, tort or otherwise, arising
// from, out of or in connection with the Software or the use of Software.
//
// ------------------------------------------------------------


#include <stdio.h>
#include <string.h>
#include "gicv3_registers.h"
#include "gicv3_lpis.h"

// The first release of ARM Compiler 6 does not support the DSB
// intrinsic.  Re-creating manually.
static __inline void __dsb(void)
{
  asm("dsb sy");
}

// ------------------------------------------------------------
// Setting location of interfaces
// ------------------------------------------------------------

struct GICv3_its_ctlr_if*     gic_its;
struct GICv3_its_int_if*      gic_its_ints;

extern struct GICv3_dist_if*  gic_dist;
extern struct GICv3_rdist_if* gic_rdist;

// Selects an ITS
// ITS_base = virtual address of ITS_base register page
void setITSBaseAddress(void* ITS_base)
{
  gic_its      = (struct GICv3_its_ctlr_if*)ITS_base;
  gic_its_ints = (struct GICv3_its_int_if*)(ITS_base + 0x010000);
  return;
}

// ------------------------------------------------------------
// Redistributor setup functions
// ------------------------------------------------------------

uint32_t setLPIConfigTableAddr(uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t IDbits)
{
  uint64_t tmp = 0;

  #ifdef DEBUG
  printf("setLPIConfigTableAddr:: Installing LPI Configuration Table on RD%d\n", rd);
  printf("setLPIConfigTableAddr:: Tabble base 0x%lx, with %d ID bits\n", addr, IDbits);
  #endif

  // The function takes the number of ID bits, the register expects (ID bits - 1)
  // If the number of IDbits is less than 14, then there are no LPIs
  // Also the maximum size of the EventID is 32 bit
  if ((IDbits < 14) || (IDbits > 24))
  {
    #ifdef DEBUG
    printf("setLPIConfigTableAddr:: ERROR - Invalid number of ID bits\n");
    #endif
    return 1;
  }

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
  gic_rdist[rd].lpis.GICR_PROPBASER = tmp;

  return 0;
}

// ------------------------------------------------------------

uint32_t setLPIPendingTableAddr(uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t IDbits)
{
  uint64_t tmp = 0;
  
  #ifdef DEBUG
  printf("setLPIPendingTableAddr:: Installing LPI Pending Table on RD%d\n", rd);
  printf("setLPIPendingTableAddr:: Tabble base 0x%lx, with %d ID bits\n", addr, IDbits);
  #endif

  // The function takes the number of ID bits, the register expects (ID bits - 1)
  // If the number of IDbits is less than 14, then there are no LPIs
  if ((IDbits < 14) || (IDbits > 24))
  {
    #ifdef DEBUG
    printf("setLPIPendingTableAddr:: ERROR - Invalid number of ID bits\n");
    #endif
    return 1;
  }

  // Zero table
  // This is ensure that all interrupts have a known (inactive) initial state
  // TBD: Fix memset to only clear required bytes!
  tmp = 1 << IDbits;
  memset((void*)addr, 0, tmp);
  __dsb();

  // Write GICR_PENDBASER
  addr =         addr       & 0x0000FFFFFFFF0000;    // PA is bits 47:16
  tmp  = addr | (attributes & 0x0700000000000F80);   // Attributes are in bits 58:56 and 11:7
  gic_rdist[rd].lpis.GICR_PENDBASER = tmp;

  return 0;
}

// ------------------------------------------------------------

// Enables LPIs for the currently selected Redistributor
void enableLPIs(uint32_t rd)
{
  #ifdef DEBUG
  printf("enableLPIs:: Enabling physical LPIs on RD%d\n", rd);
  #endif

  gic_rdist[rd].lpis.GICR_CTLR = (gic_rdist[rd].lpis.GICR_CTLR | 0x1);
  __dsb();
  return;
}

// ------------------------------------------------------------

uint32_t getRdProcNumber(uint32_t rd)
{

  return ((gic_rdist[rd].lpis.GICR_TYPER[0] >> 8) & 0xFFFF);
}

// ------------------------------------------------------------

uint32_t getMaxLPI(uint32_t rd)
{
  uint32_t max_lpi;
  
  // First check whether specified RD supports LPIs
  if ((gic_rdist[rd].lpis.GICR_TYPER[0] & 0x1) == 0)
    return 0;

  // Now find the maximum LPI
  max_lpi = ((gic_dist->GICD_TYPER >> 19) & 0x1F) + 1; // the number of bits of INTID
  max_lpi = (1 << max_lpi) - 1;                        // maximum LPI
  return max_lpi;
}

// ------------------------------------------------------------
// Configuring LPI functions
// ------------------------------------------------------------

// Configures specified LPI
// ID       = ID of LPI to be configured (must be 8192 or greater, no upper limit check)
// enable   = whether ID is enabled (1=enabled, 0=disabled)
// priority = priority for ID
uint32_t configureLPI(uint32_t rd, uint32_t ID, uint32_t enable, uint32_t priority)
{
  uint8_t* config;
  uint32_t max_lpi;
  
  #ifdef DEBUG
  printf("configureLPI:: Configuring INTID %d, with priority 0x%x and enable 0x%x, on RD%d\n", ID, priority, enable, rd);
  #endif

  // Check static limits
  max_lpi = ((gic_dist->GICD_TYPER >> 19) & 0x1F) + 1; // the number of bits of INTID
  max_lpi = (1 << max_lpi) - 1;                        // maximum LPI
  if ((ID < 8192) || (ID > max_lpi))
  {
    // INITD not within static LPI range
    #ifdef DEBUG
    printf("configureLPI:: ERROR - INTID %d is beyond supported maximum INTID %d\n", ID, max_lpi);
    #endif
    return 1;
  }

  // Check LPI fits within allocated tables
  max_lpi = (gic_rdist[rd].lpis.GICR_PROPBASER & 0x1F) + 1; // the number of bits of INTID for which there if memory allocated
  max_lpi = (1 << max_lpi) - 1;                        // maximum LPI
  if (ID > max_lpi)
  {
    // LPI not within range supported by allocated memory
    #ifdef DEBUG
    printf("configureLPI:: ERROR - INTID %d is beyond configured maximum INTID %d\n", ID, max_lpi);
    #endif
    return 1;
  }

  // Set up a pointer to the configuration table
  config = (uint8_t*)(gic_rdist[rd].lpis.GICR_PROPBASER & 0x0000FFFFFFFFF000);

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
  gic_rdist[rd].lpis.GICR_INVLPIR = ID;

  while (gic_rdist[rd].lpis.GICR_SYNCR != 0)
  {}
  #endif

  return 0;
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
uint32_t initITSCommandQueue(uint64_t addr, uint64_t attributes, uint32_t num_pages)
{
  uint64_t tmp;

  addr       = addr       & (uint64_t)0x0000FFFFFFFFF000;
  attributes = attributes & (uint64_t)0xF800000000000C00;
  num_pages  = num_pages  & 0x00000000000000FF;
  
  #ifdef DEBUG
  printf("initITSCommandQueue:: Setting up Command Queue at 0x%lx, with %d pages\n", addr, num_pages);
  #endif

  // Check number of pages is not 0
  if (num_pages == 0)
  {
    #ifdef DEBUG
    printf("initITSCommandQueue:: ERROR - Page count for Command Queue cannot be 0\n");
    #endif
    return 1;
  }

  // check number of pages within permitted max
  if (num_pages > 256)
  {
    #ifdef DEBUG
    printf("initITSCommandQueue:: ERROR - Page count for Command Queue cannot be 256\n");
    #endif
    return 1;
  }

  // work out queue size in bytes, then zero memory
  // This code assumes that VA=PA for allocated memory
  tmp = num_pages * 4096;
  memset((void*)addr, 0, tmp);

  // Combine address, attributes and size
  tmp = addr | attributes | (uint64_t)(num_pages - 1);

  gic_its->GITS_CBASER  = tmp;
  gic_its->GITS_CWRITER = 0;    // This register contains the offset from the start, hence setting to 0

  __dsb();

  return 0;
}

// ------------------------------------------------------------

// Returns the type and entry size of GITS_BASER[index] of the currently selected ITS
// index = which GITS_BASERn register to access, must be in the range 0 to 7
// type  = pointer to a uint32_t, function write the vale of the GITS_BASERn.Type to this pointer
// entry_size  = pointer to a uint32_t, function write the vale of the GITS_BASERn.Entry_Size to this pointer
uint64_t getITSTableType(uint32_t index, uint32_t* type, uint32_t* entry_size)
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
uint32_t setITSTableAddr(uint32_t index, uint64_t addr, uint64_t attributes, uint32_t page_size, uint32_t num_pages)
{
  uint64_t tmp;
  
  #ifdef DEBUG
  printf("setITSTableAddr:: Setting up ITS table %d at 0x%lx, with %d pages\n", index, addr, num_pages);
  #endif

  // Range check:
  // - there are only 8 (0-7) registers
  // - code doesn't allow for 0 pages (minimum that can be encoded into the register is 1)
  if (index > 7)
  {
    #ifdef DEBUG
    printf("initITSCommandQueue:: ERROR - Invalid index vales\n");
    #endif
    return 1;
  }

  if (num_pages == 0)
  {
    #ifdef DEBUG
    printf("initITSCommandQueue:: ERROR - Invalid number of pages\n");
    #endif
    return 1;
  }

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

  return 0;
}

// ------------------------------------------------------------

// Returns the value of GITS_TYPER.PTA bit (shifted down to LSB)
uint32_t getITSPTA(void)
{
  return ((gic_its->GITS_TYPER >> 19) & 1);
}

// ------------------------------------------------------------

// Sets the GITS_CTLR.Enabled bit
void enableITS(void)
{
  gic_its->GITS_CTLR = 1;
  return;
}

// ------------------------------------------------------------

// Clears the GITS_CTLR.Enabled bit
void disableITS(void)
{
  gic_its->GITS_CTLR = 0;
  
  // Poll for the disabling to take affect
  while((gic_its->GITS_CTLR & (1 << 31)) == 0)
  {}

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
void itsAddCommand(uint8_t* command)
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
    
  #ifdef DEBUG
  printf("itsAddCommand:: Wrote command with: \n");
  printf("DW0: %02x %02x %02x %02x %02x %02x %02x %02x\n", command[7],  command[6],  command[5],  command[4],  command[3],  command[2],  command[1],  command[0]);
  printf("DW1: %02x %02x %02x %02x %02x %02x %02x %02x\n", command[15], command[14], command[13], command[12], command[11], command[10], command[9],  command[8]);
  printf("DW2: %02x %02x %02x %02x %02x %02x %02x %02x\n", command[23], command[22], command[21], command[20], command[19], command[18], command[17], command[16]);
  printf("DW0: %02x %02x %02x %02x %02x %02x %02x %02x\n", command[31], command[30], command[29], command[28], command[27], command[26], command[25], command[24]);
  #endif

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
void itsMAPD(uint32_t device_id, uint64_t table, uint32_t size)
{
  uint8_t command[32];
  uint32_t i;

  // The command takes "actual_size - 1", the function takes
  // actual_size.  Therefore need to subtract one.
  if (size > 0)
    size--;
  else
    return; // error

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  table = table >> 8;

  // Construct command
  command[0]  = 0x8;
  command[1]  = 0x0;

  command[4]  = (uint8_t)(0xFF & device_id);
  command[5]  = (uint8_t)(0xFF & (device_id >> 8));
  command[6]  = (uint8_t)(0xFF & (device_id >> 16));
  command[7]  = (uint8_t)(0xFF & (device_id >> 24));

  command[8]  = (uint8_t)(0x3F & size);

  command[17] = (uint8_t)(0xFF & table);
  command[18] = (uint8_t)(0xFF & (table >> 8));
  command[19] = (uint8_t)(0xFF & (table >> 16));
  command[20] = (uint8_t)(0xFF & (table >> 24));
  command[21] = (uint8_t)(0xFF & (table >> 32));

  command[23] = 0x80;  // valid bit

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

// Issues a MAPC command to the currently selected ITS
// target     = the target Redistributor.  Either the PA or the ID, depending on GITS_TYPER
// collection = the collection id
void itsMAPC(uint32_t target, uint32_t collection)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;
    
  // Check whether "target" is PA or Processor Number
  if ((gic_its->GITS_TYPER & (1 << 19)) != 0)
     target = target >> 16;

  // Construct command
  command[0]  = 0x9;
  command[1]  = 0x0;

  command[16] = (uint8_t)(0xFF & collection);
  command[17] = (uint8_t)(0xFF & (collection >> 8));

  command[18] = (uint8_t)(0xFF & target);
  command[19] = (uint8_t)(0xFF & (target >> 8));
  command[20] = (uint8_t)(0xFF & (target >> 16));
  command[21] = (uint8_t)(0xFF & (target >> 24));

  command[23] = 0x80;  // valid bit

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

// Issues a MAPTI command to the currently selected ITS
// device   = the device ID
// event_id = the event id (the "ID" the peripheral will write)
// intid    = the GIC INTID (the "ID" that will be reported when readin IAR)
// cid      = the collection id
void itsMAPTI(uint32_t device_id, uint32_t event_id, uint32_t intid, uint32_t cid)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0xA;
  command[1]   = 0x0;

  command[4]   = (uint8_t)(0xFF & device_id);
  command[5]   = (uint8_t)(0xFF & (device_id >> 8));
  command[6]   = (uint8_t)(0xFF & (device_id >> 16));
  command[7]   = (uint8_t)(0xFF & (device_id >> 24));

  command[8]   = (uint8_t)(0xFF & event_id);
  command[9]   = (uint8_t)(0xFF & (event_id >> 8));
  command[10]  = (uint8_t)(0xFF & (event_id >> 16));
  command[11]  = (uint8_t)(0xFF & (event_id >> 24));

  command[12]  = (uint8_t)(0xFF & intid);
  command[13]  = (uint8_t)(0xFF & (intid >> 8));
  command[14]  = (uint8_t)(0xFF & (intid >> 16));
  command[15]  = (uint8_t)(0xFF & (intid >> 24));

  command[16]  = (uint8_t)(0xFF & cid);
  command[17]  = (uint8_t)(0xFF & (cid >> 8));

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

// Issues an INVALL command to the currently selected ITS
// cid      = the collection id
void itsINVALL(uint32_t cid)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0xD;
  command[1]   = 0x0;

  command[16]  = (uint8_t)(0xFF & cid);
  command[17]  = (uint8_t)(0xFF & (cid >> 8));

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

// Issues an INV command to the currently selected ITS
// device_id = the DeviceID
// event_id  = the EventID
void itsINV(uint32_t device_id, uint32_t event_id)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0xC;
  command[1]   = 0x0;

  command[4]   = (uint8_t)(0xFF & device_id);
  command[5]   = (uint8_t)(0xFF & (device_id >> 8));
  command[6]   = (uint8_t)(0xFF & (device_id >> 16));
  command[7]   = (uint8_t)(0xFF & (device_id >> 24));

  command[8]   = (uint8_t)(0xFF & event_id);
  command[9]   = (uint8_t)(0xFF & (event_id >> 8));
  command[10]  = (uint8_t)(0xFF & (event_id >> 16));
  command[11]  = (uint8_t)(0xFF & (event_id >> 24));

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

// Issues a SYNC command to the currently selected ITS
// target = The target Redistributor.  Either the PA or the ID, depending on GITS_TYPER
void itsSYNC(uint64_t target)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  target = target >> 16;

  // Construct command
  command[0]   = 0x5;
  command[1]   = 0x0;

  command[18] = (uint8_t)(0xFF & target);
  command[19] = (uint8_t)(0xFF & (target >> 8));
  command[20] = (uint8_t)(0xFF & (target >> 16));
  command[21] = (uint8_t)(0xFF & (target >> 24));

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

// Issues a INT command to the currently selected ITS
// device = device id
// id     = event id  (the value the peripheral would have written)
void itsINT(uint32_t device_id, uint32_t event_id)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0x3;
  command[1]   = 0x0;

  command[4]   = (uint8_t)(0xFF & device_id);
  command[5]   = (uint8_t)(0xFF & (device_id >> 8));
  command[6]   = (uint8_t)(0xFF & (device_id >> 16));
  command[7]   = (uint8_t)(0xFF & (device_id >> 24));

  command[8]   = (uint8_t)(0xFF & event_id);
  command[9]   = (uint8_t)(0xFF & (event_id >> 8));
  command[10]  = (uint8_t)(0xFF & (event_id >> 16));
  command[11]  = (uint8_t)(0xFF & (event_id >> 24));

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------
// End of giv3_lpi.c
// ------------------------------------------------------------
