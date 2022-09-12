// GICv3 Helper Functions (basic)
//
// Copyright (C) Arm Limited, 2019 All rights reserved.
//
// ------------------------------------------------------------


#include <stdio.h>
#include "stdlib.h"
#include "assert.h"
#include <string.h>
#include "gicv3_registers.h"
#include "gicv3_basic.h"

// The first release of ARM Compiler 6 does not support the DSB
// intrinsic.  Re-creating manually.
static __inline void __dsb(void)
{
  asm("dsb sy");
}

// Sets the address of the Distributor and Redistributors
// dist   = virtual address of the Distributor
// rdist  = virtual address of the first RD_base register page
static void setGICAddr(struct GICv3AddressWrapper **this, void* dist, void* rdist)
{
  uint32_t index = 0;

  (*this)->gic_dist = (struct GICv3_dist_if*)dist;
  (*this)->gic_rdist = (struct GICv3_rdist_if*)rdist;
  (*this)->gic_addr_valid = true;
  (*this)->gic_max_rd = 0;

  // Now find the maximum RD ID that I can use
  // This is used for range checking in later functions
  while(((*this)->gic_rdist[index].lpis.GICR_TYPER[0] & (1<<4)) == 0)
  {
    // Keep incrementing until GICR_TYPER.Last reports no more RDs in block
    index++;
  }
  (*this)->gic_max_rd = index;
  
  return;
}

// ------------------------------------------------------------
// Discovery function for Distributor and Redistributors
// ------------------------------------------------------------

static uint32_t getExtPPI(struct GICv3AddressWrapper **this, uint32_t rd)
{
  return (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F) * 32;
}

// ------------------------------------------------------------

// Returns the number of SPIs in the GICv3.0 range
static uint32_t getSPI(struct GICv3AddressWrapper **this)
{
  return (((*this)->gic_dist->GICD_TYPER & 0x1F) + 1)* 32;
}

// ------------------------------------------------------------

// Returns the number of SPIs in the Extended SPI range
static uint32_t getExtSPI(struct GICv3AddressWrapper **this)
{
  if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 1)
    return ((((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F) + 1) * 32;
  else
    return 0;
}


// ------------------------------------------------------------
// Distributor Functions
// ------------------------------------------------------------

// Enables and configures of the Distributor Interface
static uint32_t enableGIC(struct GICv3AddressWrapper **this)
{
  // Check that GIC pointers have been initialized, otherwise abort
  bool should_be_true =  ((*this)->gic_addr_valid == true);
  assert(should_be_true);

  // First set the ARE bits
  (*this)->gic_dist->GICD_CTLR = (1 << 5) | (1 << 4);

  // The split here is because the register layout is different once ARE==1

  // Now set the rest of the options
  (*this)->gic_dist->GICD_CTLR = 7 | (1 << 5) | (1 << 4);
  return 0;
}

// This function is called only from the master GIC.
// Updates the id of the master GIC in GICD_DCHIPR register.
static uint32_t setMultiChipOwner(struct GICv3AddressWrapper **this)
{
  uint8_t chipID = (*this)->chipID;

  // Max num of chips is 16. Also, GICD_CTLR.RWP should be 0 while configuring.
  bool should_be_true = (chipID < 16 && (((*this)->gic_dist->GICD_CTLR >> 31) == 0));
  assert(should_be_true);

  uint32_t group_enables = (*this)->gic_dist->GICD_CTLR & 0x7;
  assert(group_enables == 0); // Grp0 and Grp1 must have been disabled before this line.

  // Determine the master chip
  (*this)->gic_dist->GICD_DCHIPR = chipID << 4;

  (*this)->checkIfUpdated(this);

  return 0;
}

// This function is called only from the master GIC.
// Write the owner's routing table entry for the chip with chipID.
static uint32_t configRoutingTable(struct GICv3AddressWrapper **this, struct GICv3AddressWrapper **targetGIC)
{
  uint8_t targetID = (*targetGIC)->chipID;

  // Max num of chips is 16. Also, GICD_CTLR.RWP should be 0 while configuring.
  if (targetID > 15 || (((*this)->gic_dist->GICD_CTLR >> 31) == 1))
    return 1;

  // GICD_CHIPR Address
  uint64_t CHIPR_ADDR = (*targetGIC)->distBaseAddress >> 16; // + 0xC008;

  uint32_t group_enables = (*this)->gic_dist->GICD_CTLR & 0x7;
  assert(group_enables == 0); // Grp0 and Grp1 must have been disabled before this line.

  // Write routing table register
  // Please be reminded that GIC600 and GIC-700 have different GICD_CHIPR layout.
  // Below code follows GIC-700, because, at the moment, the only available MultiGIC
  // platform uses GIC-700, but it can be more correct by reading ID_AA64PFR0_EL1.GIC
  // field, and adjust the shift amout depending on the GIC version implied by the field.
  // For example, GIC600 is of type GICv3, and GIC-700 is of type GICv4.1.
  (*this)->gic_dist->GICD_CHIPR[targetID] = (CHIPR_ADDR << 16) |
                                          ((*targetGIC)->MIN_SPI_BLOCK << 9) |
                                          ((*targetGIC)->SPI_BLOCKS_PCHIP << 3) |
                                          1;
  (*this)->checkIfUpdated(this);

  return 0;
}

// Remove a GIC from the Routing Table
uint32_t disableGIC (struct GICv3AddressWrapper **this, uint32_t gicID)
{
  (*this)->gic_dist->GICD_CHIPR[gicID] -= ((*this)->gic_dist->GICD_CHIPR[gicID] % 2);
  (*this)->checkIfUpdated(this);
  return 0;
}

// Prohibit any writes or reads while registers are being updated
static uint32_t disableGrp0Grp1(struct GICv3AddressWrapper **this)
{
  if ( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1)
  {
    printf("CTLR processing update...\n");
    while( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1){}
  }

  (*this)->gic_dist->GICD_CTLR &= 0xfffffff8;

  if ( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1)
  {
    printf("CTLR processing update...\n");
    while( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1){}
  }
  
  return 0;
}

// Enable back reads and writes
static uint32_t enableGrp0Grp1(struct GICv3AddressWrapper **this)
{
  if ( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1)
  {
    printf("CTLR processing update...\n");
    while( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1){}
  }

  (*this)->gic_dist->GICD_CTLR |= 0x7;

  if ( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1)
  {
    printf("CTLR processing update...\n");
    while( (((*this)->gic_dist->GICD_CTLR >> 31) & 1) == 1){}
  }

  return 0;
}

// Reads PUP bit and returns only when it is 0 (when write update has finished)
static uint32_t checkIfUpdated(struct GICv3AddressWrapper **this)
{
  if ( ( (*this)->gic_dist->GICD_DCHIPR & 1) == 1)
  {
    printf("MultiChip processing update...\n");
    while( ( (*this)->gic_dist->GICD_DCHIPR & 1) == 1){}
  }

  return 0;
}

// ------------------------------------------------------------
// Redistributor Functions
// ------------------------------------------------------------

static uint32_t getRedistID(struct GICv3AddressWrapper **this, uint32_t affinity)
{
  uint32_t index = 0;

  // Check that GIC pointers have been initialized, otherwise abort
  if (!(*this)->gic_addr_valid)
    return 0xFFFFFFFF;

  do
  {
    if ((*this)->gic_rdist[index].lpis.GICR_TYPER[1] == affinity)
       return index;

    index++;
  }
  while(((*this)->gic_rdist[index].lpis.GICR_TYPER[0] & (1<<4)) == 0); // Keep looking until GICR_TYPER.Last reports no more RDs in block

  return 0xFFFFFFFF; // return -1 to signal not RD found
}

// ------------------------------------------------------------

static uint32_t wakeUpRedist(struct GICv3AddressWrapper **this, uint32_t rd)
{
  uint32_t tmp;

  // Check that GIC pointers have been initialized, otherwise abort
  assert((*this)->gic_addr_valid == true);

  // Tell the Redistributor to wake-up by clearing ProcessorSleep bit
  tmp = (*this)->gic_rdist[rd].lpis.GICR_WAKER;
  tmp = tmp & ~0x2;
  (*this)->gic_rdist[rd].lpis.GICR_WAKER = tmp;

  // Poll ChildrenAsleep bit until re-distributor wakes
  do
  {
    tmp = (*this)->gic_rdist[rd].lpis.GICR_WAKER;
  }
  while((tmp & 0x4) != 0);

  return 0;
}

// ------------------------------------------------------------
// Interrupt configuration
// ------------------------------------------------------------

static uint32_t enableInt(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd)
{
  uint32_t bank, max_ppi, max_spi;
  uint8_t* config;

  // Check that GIC pointers have been initialized, otherwise abort
  assert((*this)->gic_addr_valid == true);

  if (ID < 31)
  {
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

     // SGI or PPI
     ID   = ID & 0x1f;    // ... and which bit within the register
     ID   = 1 << ID;      // Move a '1' into the correct bit position

     (*this)->gic_rdist[rd].sgis.GICR_ISENABLER[0] = ID;
  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ISENABLER[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    max_ppi = (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
      return 1;  // Extended PPI range not present
    else if ((max_ppi == 1) && (ID > 1087))
      return 1;  // Extended PPI range implemented, but supplied INTID beyond range

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_rdist[rd].sgis.GICR_ISENABLER[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ISENABLERE[bank] = ID;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

static uint32_t disableInt(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd)
{
  uint32_t bank, max_ppi, max_spi;
  uint8_t* config;

  // Check that GIC pointers have been initialized, otherwise abort
  assert((*this)->gic_addr_valid == true);

  if (ID < 31)
  {
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

    // SGI or PPI
    ID   = ID & 0x1f;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_rdist[rd].sgis.GICR_ICENABLER[0] = ID;
  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ICENABLER[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

    // Check Ext PPI implemented
    max_ppi = (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
      return 1;  // Extended PPI range not present
    else if ((max_ppi == 1) && (ID > 1087))
      return 1;  // Extended PPI range implemented, but supplied INTID beyond range

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_rdist[rd].sgis.GICR_ICENABLER[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }


    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ICENABLERE[bank] = ID;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

static uint32_t setIntPriority(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd, uint8_t priority)
{
  uint8_t* config;
  uint32_t max_ppi, max_spi;

  // Check that GIC pointers have been initialized, otherwise abort
  assert((*this)->gic_addr_valid == true);

  if (ID < 31)
  {
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

    // SGI or PPI
    (*this)->gic_rdist[rd].sgis.GICR_IPRIORITYR[ID] = priority;
  }
  else if (ID < 1020)
  {
    // SPI
    (*this)->gic_dist->GICD_IPRIORITYR[ID] = priority;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    max_ppi = (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
      return 1;  // Extended PPI range not present
    else if ((max_ppi == 1) && (ID > 1087))
      return 1;  // Extended PPI range implemented, but supplied INTID beyond range

    ID   = ID - 1024;
    (*this)->gic_rdist[rd].sgis.GICR_IPRIORITYR[ID] = priority;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }

    (*this)->gic_dist->GICD_IPRIORITYRE[(ID-4096)] = priority;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

static uint32_t setIntType(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd, uint32_t type)
{
  uint8_t* config;
  uint32_t bank, tmp, conf, max_spi;
  
  // Check that GIC pointers have been initialized, otherwise abort
  assert((*this)->gic_addr_valid == true);

  if (ID < 31)
  {
    // SGI or PPI
    // Config of SGIs is fixed
    // It is IMP DEF whether ICFG for PPIs is write-able, on Arm implementations it is fixed
    return 1;
  }
  else if (ID < 1020)
  {
    // SPI
    type = type & 0x3;            // Mask out unused bits

    bank = ID/16;                 // There are 16 IDs per register, need to work out which register to access
    ID   = ID & 0xF;              // ... and which field within the register
    ID   = ID * 2;                // Convert from which field to a bit offset (2-bits per field)

    conf = conf << ID;            // Move configuration value into correct bit position
  
    tmp = (*this)->gic_dist->GICD_ICFGR[bank];     // Read current vlase
    tmp = tmp & ~(0x3 << ID);             // Clear the bits for the specified field
    tmp = tmp | conf;                     // OR in new configuration
    (*this)->gic_dist->GICD_ICFGR[bank] = tmp;     // Write updated value back
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);
     // TBD - complete bounds check
    }

    type = type & 0x3;            // Mask out unused bits

    ID   = ID - 4096;
    bank = ID/16;                 // There are 16 IDs per register, need to work out which register to access
    ID   = ID & 0xF;              // ... and which field within the register
    ID   = ID * 2;                // Convert from which field to a bit offset (2-bits per field)

    conf = conf << ID;            // Move configuration value into correct bit position
  
    tmp = (*this)->gic_dist->GICD_ICFGRE[bank];     // Read current vlase
    tmp = tmp & ~(0x3 << ID);             // Clear the bits for the specified field
    tmp = tmp | conf;                     // OR in new configuration
    (*this)->gic_dist->GICD_ICFGRE[bank] = tmp;     // Write updated value back
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

static uint32_t setIntGroup(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd, uint32_t security)
{
  uint8_t* config;
  uint32_t bank, tmp, group, mod, max_ppi, max_spi;

  // Check that GIC pointers have been initialized, otherwise abort
  assert((*this)->gic_addr_valid == true);

  if (ID < 31)
  {
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

    // SGI or PPI
    ID   = ID & 0x1f;    // Find which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    // Read current values
    group = (*this)->gic_rdist[rd].sgis.GICR_IGROUPR[0];
    mod   = (*this)->gic_rdist[rd].sgis.GICR_IGRPMODR[0];

    // Update required bits
    switch (security)
    {
      case GICV3_GROUP0:
        group = (group & ~ID);
        mod   = (mod   & ~ID);
        break;

      case GICV3_GROUP1_SECURE:
        group = (group & ~ID);
        mod   = (mod   | ID);
        break;
  
      case GICV3_GROUP1_NON_SECURE:
        group = (group | ID);
        mod   = (mod   & ~ID);
        break;
  
      default:
        return 1;
    }

    // Write modified version back
    (*this)->gic_rdist[rd].sgis.GICR_IGROUPR[0] = group;
    (*this)->gic_rdist[rd].sgis.GICR_IGRPMODR[0] = mod;

  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    group = (*this)->gic_dist->GICD_IGROUPR[bank];
    mod   = (*this)->gic_dist->GICD_GRPMODR[bank];
  
    switch (security)
    {
      case GICV3_GROUP0:
        group = (group & ~ID);
        mod   = (mod   & ~ID);
        break;
  
      case GICV3_GROUP1_SECURE:
        group = (group & ~ID);
        mod   = (mod   | ID);
        break;
  
      case GICV3_GROUP1_NON_SECURE:
        group = (group | ID);
        mod   = (mod   & ~ID);
        break;
  
      default:
        return 1;
    }
  
    (*this)->gic_dist->GICD_IGROUPR[bank] = group;
    (*this)->gic_dist->GICD_GRPMODR[bank] = mod;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    max_ppi = (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
      return 1;  // Extended PPI range not present
    else if ((max_ppi == 1) && (ID > 1087))
      return 1;  // Extended PPI range implemented, but supplied INTID beyond range

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

   // Read current values
   group = (*this)->gic_rdist[rd].sgis.GICR_IGROUPR[bank];
   mod   = (*this)->gic_rdist[rd].sgis.GICR_IGRPMODR[bank];
   
    // Update required bits
    switch (security)
    {
      case GICV3_GROUP0:
        group = (group & ~ID);
        mod   = (mod   & ~ID);
        break;

      case GICV3_GROUP1_SECURE:
        group = (group & ~ID);
        mod   = (mod   | ID);
        break;

      case GICV3_GROUP1_NON_SECURE:
        group = (group | ID);
        mod   = (mod   & ~ID);
        break;

      default:
        return 1;
    }

    // Write modified version back
    (*this)->gic_rdist[rd].sgis.GICR_IGROUPR[bank] = group;
    (*this)->gic_rdist[rd].sgis.GICR_IGRPMODR[bank] = mod;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

   // Read current values
   group = (*this)->gic_dist->GICD_IGROUPRE[bank];
   mod   = (*this)->gic_dist->GICD_IGRPMODRE[bank];
   
    // Update required bits
    switch (security)
    {
      case GICV3_GROUP0:
        group = (group & ~ID);
        mod   = (mod   & ~ID);
        break;

      case GICV3_GROUP1_SECURE:
        group = (group & ~ID);
        mod   = (mod   | ID);
        break;

      case GICV3_GROUP1_NON_SECURE:
        group = (group | ID);
        mod   = (mod   & ~ID);
        break;

      default:
        return 1;
    }

    // Write modified version back
    (*this)->gic_dist->GICD_IGROUPRE[bank] = group;
    (*this)->gic_dist->GICD_IGRPMODRE[bank] = mod;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

#define GICV3_ROUTE_AFF3_SHIFT           (8)

// Sets the target CPUs of the specified ID
// For 'target' use one of the above defines
// ID       = INTID of interrupt (ID must be less than 1020)
// mode     = Routing mode
// aff<n>   = Affinity co-ordinate of target
static uint32_t setIntRoute(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t mode, uint32_t affinity)
{
  uint64_t tmp, max_spi;
  
  // Check that GIC pointers have been initialized, otherwise abort
  if (!(*this)->gic_addr_valid)
    return 0xFFFFFFFF;

  // Check for SPI ranges
  if (!((ID > 31) && (ID < 1020)))
  {
    // Not a GICv3.0 SPI
    
    if (!((ID > 4096) && (ID < 5120)))
    {
      // Not a GICv3.1 SPI either
      return 1;
    }
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }
  }

  // Combine routing in
  tmp = (uint64_t)(affinity & 0x00FFFFFF) |
        (((uint64_t)affinity & 0xFF000000) << GICV3_ROUTE_AFF3_SHIFT) |
          (uint64_t)mode;
          

  if ((ID > 31) && (ID < 1020))
    (*this)->gic_dist->GICD_ROUTER[ID] = tmp;
  else
     (*this)->gic_dist->GICD_ROUTERE[(ID-4096)] = tmp;

  return 0;
}

// ----------------------------------------------------------
// Interrupt state
// ------------------------------------------------------------

static uint32_t setIntPending(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd)
{
  uint8_t* config;
  uint32_t bank, tmp, max_ppi, max_spi;
  
  // Check that GIC pointers have been initialized, otherwise abort
  if (!(*this)->gic_addr_valid)
    return 0xFFFFFFFF;

  if (ID < 31)
  {
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

    ID   = ID & 0x1f;    // Find which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    (*this)->gic_rdist[rd].sgis.GICR_ISPENDR[0] = ID;

  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register
  
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    (*this)->gic_dist->GICD_ISPENDR[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    max_ppi = (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
      return 1;  // Extended PPI range not present
    else if ((max_ppi == 1) && (ID > 1087))
      return 1;  // Extended PPI range implemented, but supplied INTID beyond range

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_rdist[rd].sgis.GICR_ISPENDR[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ISPENDRE[bank] = ID;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

static uint32_t clearIntPending(struct GICv3AddressWrapper **this, uint32_t ID, uint32_t rd)
{
  uint8_t* config;
  uint32_t bank, tmp, max_ppi, max_spi;
  
  // Check that GIC pointers have been initialized, otherwise abort
  if (!(*this)->gic_addr_valid)
    return 0xFFFFFFFF;

  if (ID < 31)
  {
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;

    ID   = ID & 0x1f;    // Find which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    (*this)->gic_rdist[rd].sgis.GICR_ICPENDR[0] = ID;

  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ICPENDR[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > (*this)->gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    max_ppi = (((*this)->gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
      return 1;  // Extended PPI range not present
    else if ((max_ppi == 1) && (ID > 1087))
      return 1;  // Extended PPI range implemented, but supplied INTID beyond range

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_rdist[rd].sgis.GICR_ICPENDR[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if ((((*this)->gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
      return 1;  // GICD_TYPER.ESPI==0: Extended SPI range not present
    else
    {
      max_spi = (((*this)->gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
      max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
      max_spi = max_spi + 4096;                          // Range starts at 4096
      
      if (!(ID < max_spi))
        return 1;
    }

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    (*this)->gic_dist->GICD_ICPENDRE[bank] = ID;
  }
  else
    return 1;

  return 0;
}

static void printState(struct GICv3AddressWrapper **this)
{

  printf("------------------------------------------\n");

  printf("GIC ID: %d\n", (unsigned)(*this)->chipID);
  printf("GICD_CHIPSR: 0x%04X\n", (*this)->gic_dist->GICD_CHIPSR);
  printf("GICD_DCHIPR: 0x%04X\n", (*this)->gic_dist->GICD_DCHIPR);
  for (unsigned i = 0; i < 16; i++)
  {
    printf("GIC_CHIPR%u: 0x%08lX\t\t", i, (*this)->gic_dist->GICD_CHIPR[i]);
    if((i + 1) % 4 == 0)
      printf("\n");
  }

  printf("\n");

  return;
}

// Constructor for GICv3AddressWrapper struct 
struct GICv3AddressWrapper *allocGIC(uint8_t chipID, uint64_t distBase, uint64_t RdistBase, uint8_t spiBlocks)
{
    struct GICv3AddressWrapper *this;
    this = (struct GICv3AddressWrapper*)malloc(sizeof(struct GICv3AddressWrapper));

    // Base Address initialization
    this->chipID              = chipID;
    this->distBaseAddress     = distBase;
    this->RdistBaseAddress    = RdistBase;
    this->SPI_BLOCKS_PCHIP    = spiBlocks;
    this->MIN_SPI_BLOCK       = spiBlocks * chipID;

    // Function pointers initialization
    this->setGICAddr          =   setGICAddr;
    this->getExtPPI           =   getExtPPI;
    this->getSPI              =   getSPI;
    this->getExtSPI           =   getExtSPI;
    this->enableGIC           =   enableGIC;
    this->setMultiChipOwner   =   setMultiChipOwner;
    this->configRoutingTable  =   configRoutingTable;
    this->disableGrp0Grp1     =   disableGrp0Grp1;
    this->enableGrp0Grp1      =   enableGrp0Grp1;
    this->checkIfUpdated      =   checkIfUpdated;
    this->getRedistID         =   getRedistID;
    this->wakeUpRedist        =   wakeUpRedist;
    this->enableInt           =   enableInt;
    this->disableInt          =   disableInt;
    this->setIntPriority      =   setIntPriority;
    this->setIntType          =   setIntType;
    this->setIntGroup         =   setIntGroup;
    this->setIntRoute         =   setIntRoute;
    this->setIntPending       =   setIntPending;
    this->clearIntPending     =   clearIntPending;
    this->printState          =   printState;
    this->disableGIC          =   disableGIC;
    return this;
}

// Destructor for GICv3AddressWrapper struct 
void DeallocGIC(struct GICv3AddressWrapper *this)
{
  free(this);
  return;
}

// ------------------------------------------------------------
// End of giv3_basic.c
// ------------------------------------------------------------
