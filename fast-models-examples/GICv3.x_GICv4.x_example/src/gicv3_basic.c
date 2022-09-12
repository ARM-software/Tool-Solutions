// ----------------------------------------------------------
// GICv3 Helper Functions (basic)
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
#include "gicv3_basic.h"

// The first release of ARM Compiler 6 does not support the DSB
// intrinsic.  Re-creating manually.
static __inline void __dsb(void)
{
  asm("dsb sy");
}

// ------------------------------------------------------------
// Setting location of interfaces
// ------------------------------------------------------------

struct GICv3_dist_if*       gic_dist;
struct GICv3_rdist_if*      gic_rdist;

static uint32_t gic_addr_valid = 0;
static uint32_t gic_max_rd = 0;

// Sets the address of the Distributor and Redistributors
// dist   = virtual address of the Distributor
// rdist  = virtual address of the first RD_base register page
void setGICAddr(void* dist, void* rdist)
{
  uint32_t index = 0;

  gic_dist = (struct GICv3_dist_if*)dist;
  gic_rdist = (struct GICv3_rdist_if*)rdist;
  gic_addr_valid = 1;

  // Now find the maximum RD ID that I can use
  // This is used for range checking in later functions
  while((gic_rdist[index].lpis.GICR_TYPER[0] & (1<<4)) == 0) // Keep incrementing until GICR_TYPER.Last reports no more RDs in block
  {
    index++;
  }

  gic_max_rd = index;
  
  return;
}

// ------------------------------------------------------------
// Discovery function for Distributor and Redistributors
// ------------------------------------------------------------

uint32_t getExtPPI(uint32_t rd)
{
  return (((gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F) + 1) * 32;
}

// ------------------------------------------------------------

// Returns the number of SPIs in the GICv3.0 range
uint32_t getSPI(void)
{
  return ((gic_dist->GICD_TYPER & 0x1F) + 1)* 32;
}

// ------------------------------------------------------------

// Returns the number of SPIs in the Extended SPI range
uint32_t getExtSPI(void)
{
  if (((gic_dist->GICD_TYPER >> 8) & 0x1) == 1)
    return (((gic_dist->GICD_TYPER >> 27) & 0x1F) + 1) * 32;
  else
    return 0;
}

// ------------------------------------------------------------

// Returns 1 if the specified INTID is within the implemented Extended PPI range

static uint32_t isValidExtPPI(uint32_t rd, uint32_t ID)
{
    uint32_t max_ppi;

    max_ppi = ((gic_rdist[rd].lpis.GICR_TYPER[0] >> 27) & 0x1F);
    if (max_ppi == 0)
    {
      #ifdef DEBUG
      printf("isValidExtPPI:: Extended PPI range not implemented, INTID %d is invalid.\n", ID);
      #endif
      return 0;
    }
    else if ((max_ppi == 1) && (ID > 1087))
    {
      #ifdef DEBUG
      printf("isValidExtPPI:: INTID %d outside of implemented range.\n", ID);
      #endif
      return 0;  // Extended PPI range implemented, but supplied INTID beyond range
    }

  return 1;
}

// ------------------------------------------------------------

// Returns 1 if the specified INTID is within the implemented Extended SPI range

static uint32_t isValidExtSPI(uint32_t ID)
{
  uint32_t max_spi;

  // Check Ext SPI implemented
  if (((gic_dist->GICD_TYPER >> 8) & 0x1) == 0)
  {
    #ifdef DEBUG
    printf("isValidExtSPI:: Extended SPI range not implemented, INTID %d is invalid.\n", ID);
    #endif
    return 0;  // GICD_TYPER.ESPI==0: Extended SPI range not present
  }
  else
  {
    max_spi = ((gic_dist->GICD_TYPER >> 27) & 0x1F);   // Get field which reports the number ESPIs in blocks of 32, minus 1
    max_spi = (max_spi + 1) * 32;                      // Convert into number of ESPIs
    max_spi = max_spi + 4096;                          // Range starts at 4096

    if (!(ID < max_spi))
    {
      #ifdef DEBUG
      printf("isValidExtSPI:: INTID %d is out of implemented range.\n", ID);
      #endif
      return 0;
    }
  }

  return 1;
}

// ------------------------------------------------------------
// Distributor Functions
// ------------------------------------------------------------

// Enables and configures of the Distributor Interface
uint32_t enableGIC(void)
{
  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 1;

  // First set the ARE bits
  gic_dist->GICD_CTLR = (1 << 5) | (1 << 4);

  // The split here is because the register layout is different once ARE==1

  // Now set the rest of the options
  gic_dist->GICD_CTLR = 7 | (1 << 5) | (1 << 4);
  return 0;
}

// ------------------------------------------------------------
// Redistributor Functions
// ------------------------------------------------------------

uint32_t getRedistID(uint32_t affinity)
{
  uint32_t index = 0;

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 0xFFFFFFFF;

  do
  {
    if (gic_rdist[index].lpis.GICR_TYPER[1] == affinity)
       return index;

    index++;
  }
  while(index <= gic_max_rd);

  return 0xFFFFFFFF; // return -1 to signal not RD found
}

// ------------------------------------------------------------

uint32_t wakeUpRedist(uint32_t rd)
{
  uint32_t tmp;

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 1;

  // Tell the Redistributor to wake-up by clearing ProcessorSleep bit
  tmp = gic_rdist[rd].lpis.GICR_WAKER;
  tmp = tmp & ~0x2;
  gic_rdist[rd].lpis.GICR_WAKER = tmp;

  // Poll ChildrenAsleep bit until Redistributor wakes
  do
  {
    tmp = gic_rdist[rd].lpis.GICR_WAKER;
  }
  while((tmp & 0x4) != 0);

  return 0;
}

// ------------------------------------------------------------
// Interrupt configuration
// ------------------------------------------------------------

uint32_t enableInt(uint32_t ID, uint32_t rd)
{
  uint32_t bank, max_ppi, max_spi;
  uint8_t* config;

  #ifdef DEBUG
  printf("enableInt:: Enabling INTID %d on RD%d\n", ID, rd);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
  {
    #ifdef DEBUG
    printf("enableInt:: ERROR - GIC pointers not intialized\n");
    #endif
    return 1;
  }

  if (ID < 31)
  {
    // Check rd in range
    if (rd > gic_max_rd)
    {
       #ifdef DEBUG
       printf("enableInt:: ERROR - Invalid RD index.\n");
       #endif
       return 1;
    }

     // SGI or PPI
     ID   = ID & 0x1f;    // ... and which bit within the register
     ID   = 1 << ID;      // Move a '1' into the correct bit position

     gic_rdist[rd].sgis.GICR_ISENABLER[0] = ID;
  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ISENABLER[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > gic_max_rd)
    {
       #ifdef DEBUG
       printf("enableInt:: ERROR - Invalid RD index.\n");
       #endif
       return 1;
    }
    
    // Check Ext PPI implemented
    if (isValidExtPPI(rd, ID) == 0)
       return 1;

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_rdist[rd].sgis.GICR_ISENABLER[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ISENABLERE[bank] = ID;
  }
  else
  {
    #ifdef DEBUG
    printf("enableInt:: ERROR - Invalid interrupt.\n");
    #endif
    return 1;
  }

  return 0;
}

// ------------------------------------------------------------

uint32_t disableInt(uint32_t ID, uint32_t rd)
{
  uint32_t bank, max_ppi, max_spi;
  uint8_t* config;

  #ifdef DEBUG
  printf("disableInt:: Disabling INTID %d on RD%d\n", ID, rd);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
  {
    #ifdef DEBUG
    printf("disableInt:: ERROR - GIC pointers not intialized\n");
    #endif
    return 1;
  }

  if (ID < 31)
  {
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;

    // SGI or PPI
    ID   = ID & 0x1f;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_rdist[rd].sgis.GICR_ICENABLER[0] = ID;
  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ICENABLER[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > gic_max_rd)
    {
      #ifdef DEBUG
      printf("disableInt:: ERROR - Extended PPI range not implemented.\n");
      #endif
      return 1;
    }

    // Check Ext PPI implemented
    if (isValidExtPPI(rd, ID) == 0)
       return 1;

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_rdist[rd].sgis.GICR_ICENABLER[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;


    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ICENABLERE[bank] = ID;
  }
  else
  {
    #ifdef DEBUG
    printf("disableInt:: ERROR - Invalid interrupt.\n");
    #endif
    return 1;
  }

  return 0;
}

// ------------------------------------------------------------

uint32_t setIntPriority(uint32_t ID, uint32_t rd, uint8_t priority)
{
  uint8_t* config;
  uint32_t max_ppi, max_spi;

  #ifdef DEBUG
  printf("setIntPriority:: Setting priority of INTID %d on RD%d to 0x%x\n", ID, rd, priority);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
  {
    #ifdef DEBUG
    printf("setIntPriority:: ERROR - GIC pointers not intialized\n");
    #endif
    return 1;
  }

  if (ID < 31)
  {
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;

    // SGI or PPI
    gic_rdist[rd].sgis.GICR_IPRIORITYR[ID] = priority;
  }
  else if (ID < 1020)
  {
    // SPI
    gic_dist->GICD_IPRIORITYR[ID] = priority;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    if (isValidExtPPI(rd, ID) == 0)
       return 1;

    ID   = ID - 1024;
    gic_rdist[rd].sgis.GICR_IPRIORITYR[ID] = priority;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;

    gic_dist->GICD_IPRIORITYRE[(ID-4096)] = priority;
  }
  else
  {
    #ifdef DEBUG
    printf("setIntPriority:: ERROR - Invalid interrupt.\n");
    #endif
    return 1;
  }

  return 0;
}

// ------------------------------------------------------------

uint32_t setIntType(uint32_t ID, uint32_t rd, uint32_t type)
{
  uint8_t* config;
  uint32_t bank, tmp, conf, max_spi;
  
  #ifdef DEBUG
  printf("setIntType:: Setting INTID %d on RD%d as type 0x%x\n", ID, rd, type);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 1;

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
  
    tmp = gic_dist->GICD_ICFGR[bank];     // Read current value
    tmp = tmp & ~(0x3 << ID);             // Clear the bits for the specified field
    tmp = tmp | conf;                     // OR in new configuration
    gic_dist->GICD_ICFGR[bank] = tmp;     // Write updated value back
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;

    type = type & 0x3;            // Mask out unused bits

    ID   = ID - 4096;
    bank = ID/16;                 // There are 16 IDs per register, need to work out which register to access
    ID   = ID & 0xF;              // ... and which field within the register
    ID   = ID * 2;                // Convert from which field to a bit offset (2-bits per field)

    conf = conf << ID;            // Move configuration value into correct bit position
  
    tmp = gic_dist->GICD_ICFGRE[bank];    // Read current value
    tmp = tmp & ~(0x3 << ID);             // Clear the bits for the specified field
    tmp = tmp | conf;                     // OR in new configuration
    gic_dist->GICD_ICFGRE[bank] = tmp;    // Write updated value back
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

uint32_t setIntGroup(uint32_t ID, uint32_t rd, uint32_t security)
{
  uint8_t* config;
  uint32_t bank, tmp, group, mod, max_ppi, max_spi;

  #ifdef DEBUG
  printf("setIntGroup:: Setting INTID %d on RD%d as groups 0x%x\n", ID, rd, security);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 1;

  if (ID < 31)
  {
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;

    // SGI or PPI
    ID   = ID & 0x1f;    // Find which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    // Read current values
    group = gic_rdist[rd].sgis.GICR_IGROUPR[0];
    mod   = gic_rdist[rd].sgis.GICR_IGRPMODR[0];

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
    gic_rdist[rd].sgis.GICR_IGROUPR[0] = group;
    gic_rdist[rd].sgis.GICR_IGRPMODR[0] = mod;

  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    group = gic_dist->GICD_IGROUPR[bank];
    mod   = gic_dist->GICD_GRPMODR[bank];
  
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
  
    gic_dist->GICD_IGROUPR[bank] = group;
    gic_dist->GICD_GRPMODR[bank] = mod;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    if (isValidExtPPI(rd, ID) == 0)
       return 1;

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

   // Read current values
   group = gic_rdist[rd].sgis.GICR_IGROUPR[bank];
   mod   = gic_rdist[rd].sgis.GICR_IGRPMODR[bank];
   
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
    gic_rdist[rd].sgis.GICR_IGROUPR[bank] = group;
    gic_rdist[rd].sgis.GICR_IGRPMODR[bank] = mod;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

   // Read current values
   group = gic_dist->GICD_IGROUPRE[bank];
   mod   = gic_dist->GICD_IGRPMODRE[bank];
   
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
    gic_dist->GICD_IGROUPRE[bank] = group;
    gic_dist->GICD_IGRPMODRE[bank] = mod;
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
uint32_t setIntRoute(uint32_t ID, uint32_t mode, uint32_t affinity)
{
  uint64_t tmp, max_spi;
  
  #ifdef DEBUG
  printf("setIntRoute:: Routing INTID %d to mode=0x%x and affinity=0x%08x\n", ID, mode, affinity);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 0xFFFFFFFF;

  // Check for SPI ranges
  if (!((ID > 31) && (ID < 1020)))
  {
    // Not a GICv3.0 SPI
    
    if (!((ID > 4095) && (ID < 5120)))
    {
      // Not a GICv3.1 SPI either
      #ifdef DEBUG
      printf("setIntRoute:: ERROR - Cannot set routing information for non-SPI\n");
      #endif
      return 1;
    }
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;
  }

  // Combine routing in
  tmp = (uint64_t)(affinity & 0x00FFFFFF) |
        (((uint64_t)affinity & 0xFF000000) << GICV3_ROUTE_AFF3_SHIFT) |
          (uint64_t)mode;
          

  if ((ID > 31) && (ID < 1020))
    gic_dist->GICD_ROUTER[ID] = tmp;
  else
     gic_dist->GICD_ROUTERE[(ID-4096)] = tmp;

  return 0;
}

// ----------------------------------------------------------
// Interrupt state
// ------------------------------------------------------------

uint32_t setIntPending(uint32_t ID, uint32_t rd)
{
  uint8_t* config;
  uint32_t bank, tmp, max_ppi, max_spi;
  
  #ifdef DEBUG
  printf("setIntPending:: Setting INTID %d on RD%d as Pending\n", ID, rd);
  #endif
  
  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 0xFFFFFFFF;

  if (ID < 31)
  {
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;

    ID   = ID & 0x1f;    // Find which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_rdist[rd].sgis.GICR_ISPENDR[0] = ID;

  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register
  
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    gic_dist->GICD_ISPENDR[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    if (isValidExtPPI(rd, ID) == 0)
       return 1;

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_rdist[rd].sgis.GICR_ISPENDR[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ISPENDRE[bank] = ID;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------

uint32_t clearIntPending(uint32_t ID, uint32_t rd)
{
  uint8_t* config;
  uint32_t bank, tmp, max_ppi, max_spi;
  
  #ifdef DEBUG
  printf("clearIntPending:: Clearing pending state of INTID %d on RD%d\n", ID, rd);
  #endif

  // Check that GIC pointers are valid
  if (gic_addr_valid==0)
    return 0xFFFFFFFF;

  if (ID < 31)
  {
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;

    ID   = ID & 0x1f;    // Find which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position
  
    gic_rdist[rd].sgis.GICR_ICPENDR[0] = ID;

  }
  else if (ID < 1020)
  {
    // SPI
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1f;    // ... and which bit within the register

    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ICPENDR[bank] = ID;
  }
  else if ((ID > 1055) && (ID < 1120))
  {
    // Extended PPI
    
    // Check rd in range
    if (rd > gic_max_rd)
       return 1;
    
    // Check Ext PPI implemented
    if (isValidExtPPI(rd, ID) == 0)
       return 1;

    ID   = ID - 1024;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_rdist[rd].sgis.GICR_ICPENDR[bank] = ID;
  }
  else if ((ID > 4095) && (ID < 5120))
  {
    // Extended SPI
    
    // Check Ext SPI implemented
    if (isValidExtSPI(ID) == 0)
       return 1;

    ID   = ID - 4096;
    bank = ID/32;        // There are 32 IDs per register, need to work out which register to access
    ID   = ID & 0x1F;    // ... and which bit within the register
    ID   = 1 << ID;      // Move a '1' into the correct bit position

    gic_dist->GICD_ICPENDRE[bank] = ID;
  }
  else
    return 1;

  return 0;
}

// ------------------------------------------------------------
// End of giv3_basic.c
// ------------------------------------------------------------
