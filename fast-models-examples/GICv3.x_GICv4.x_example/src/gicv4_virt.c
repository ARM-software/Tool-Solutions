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
#include "gicv4_virt.h"

extern void itsAddCommand(uint8_t* command);

// The first release of ARM Compiler 6 does not support the DSB
// intrinsic.  Re-creating manually.
static __inline void __dsb(void)
{
  asm("dsb sy");
}

// ------------------------------------------------------------
// Setting location of interfaces
// ------------------------------------------------------------

extern struct GICv3_its_ctlr_if*     gic_its;
extern struct GICv3_its_int_if*      gic_its_ints;
       struct GICv3_its_sgi_if*      gic_its_sgi;

extern struct GICv3_rdist_if* gic_rdist;

// ------------------------------------------------------------
// Address space set up
// ------------------------------------------------------------

void setSGIBaseAddr(void)
{
  gic_its_sgi = (struct GICv3_its_sgi_if*)((uint64_t)gic_its + 0x20000);
}


// ------------------------------------------------------------
// Discovery
// ------------------------------------------------------------

uint32_t isGICv4x(uint32_t rd)
{
  if (((gic_rdist[rd].lpis.GICR_TYPER[0] >> 1) & 0x1) == 0)
    return GICV3_v3X;  // GICR_TYPER.VLPIS==0, so GICv3.x


  if (((gic_rdist[rd].lpis.GICR_TYPER[0] >> 7) & 0x1) == 0)
    return GICV3_v40;  // GICR_TYPER.RVPEID==0, so GICv4.0

  // GICR_TYPER.{VLPIS,RVPEID}=={1,1} => GICv4.1
  return GICV3_v41;
}

// ------------------------------------------------------------

uint32_t hasVSGI(uint32_t rd)
{
  uint32_t its_type, rd_type;

  its_type = (gic_its->GITS_TYPER >> 39) & 0x1;
  rd_type  = (gic_rdist[rd].lpis.GICR_TYPER[0] >> 26) & 0x1;

  // Return 1 if both RD and ITS support vSGI, otherwise return 0
  return (its_type & rd_type);
}

// ------------------------------------------------------------
// Redistributor setup functions
// ------------------------------------------------------------

uint32_t setVPEConfTableAddr(uint32_t rd, uint64_t addr, uint64_t attributes, uint32_t num_pages)
{
  uint64_t tmp;

  addr       = addr       & (uint64_t)0x0000FFFFFFFFF000;
  //attributes = attributes & (uint64_t)0xF800000000000C00;
  num_pages  = num_pages  & 0x000000000000007F;

  #ifdef DEBUG
  printf("setVPEConfTableAddr:: Setting up vPE Configuration Table on RD%d at 0x%lx, with %d pages\n", rd, addr, num_pages);
  #endif

  // check number of pages is not 0
  if (num_pages == 0)
  {
    #ifdef DEBUG
    printf("setVPEConfTableAddr:: ERROR - Page count for Command Queue cannot be 0\n");
    #endif
    return 1;
  }

  // check the number of pages is within the maximum
  if (num_pages > 127)
  {
    #ifdef DEBUG
    printf("setVPEConfTableAddr:: ERROR - Page count for Command Queue cannot be greater than 127\n");
    #endif
    return 1;
  }

  // work out queue size in bytes, then zero memory
  // This code assumes that VA=PA for allocated memory
  tmp = num_pages * 4096;
  memset((void*)addr, 0, tmp);

  // Combine address, attributes and size
  // TBD add in attributes, current fixed as Device
  tmp = addr | (num_pages - 1) | ((uint64_t)1 << 52) | (uint64_t)1 << 63;

  gic_rdist[rd].vlpis.GICR_VPROPBASER = tmp;

  return 0;
}

// ------------------------------------------------------------

uint32_t makeResident(uint32_t rd, uint32_t vpeid, uint32_t g0, uint32_t g1)
{
  #ifdef DEBUG
  printf("makeResident:: Making vPEID 0x%x resident on RD%d\n", vpeid, rd);
  #endif

  // Check there isn't already a vPE resident
  if ((gic_rdist[rd].vlpis.GICR_VPENDBASER & ((uint64_t)1 << 63)) == 1)
  {
    #ifdef DEBUG
    printf("makeResident:: ERROR - a vPE is already resident\n");
    #endif
    return 0xFFFFFFFF;
  }

  gic_rdist[rd].vlpis.GICR_VPENDBASER = ((uint64_t)vpeid & 0xFFFF) |
                                        ((uint64_t)1 << 63) |
                                        ((uint64_t)(g1 & 0x1) << 59) |
                                        ((uint64_t)(g0 & 0x1) << 58);


  // Poll for residency to take affect
  while ((gic_rdist[rd].vlpis.GICR_VPENDBASER & ((uint64_t)0x1 << 60)) != 0)
  {}

  return 0;
}

// ------------------------------------------------------------

// Enables LPIs for the currently selected Redistributor
uint32_t makeNotResident(uint32_t rd, uint32_t db)
{
  // First clear the valid bit
  gic_rdist[rd].vlpis.GICR_VPENDBASER = ((uint64_t)(db & 0x1) << 62);

  // Now poll for dirty==0
  while ((gic_rdist[rd].vlpis.GICR_VPENDBASER & ((uint64_t)0x1 << 60)) != 0)
  {}

  // Return pending last
  return (gic_rdist[rd].vlpis.GICR_VPENDBASER & ((uint64_t)0x1 << 61));
}


// ------------------------------------------------------------
// Configuring LPI functions
// ------------------------------------------------------------

// Configures specified vLPI
uint32_t configureVLPI(uint8_t* table, uint32_t ID, uint32_t enable, uint32_t priority)
{
 uint8_t* config;

  #ifdef DEBUG
  printf("configureVLPI:: Configuring vINITD %d as priority 0x%x and enable=%d\n", ID, priority, enable);
  #endif

  // Check lower limit
  if (ID < 8192)
  {
    #ifdef DEBUG
    printf("configureVLPI:: ERROR - INTID %d is not a valid LPI\n", ID);
    #endif
    return 1;
  }
    
  // TBD - Check the upper limit, which requires knowing the table size.

  // Mask off unused bits of the priority and enable
  enable = enable & 0x1;
  priority = priority & 0x7C;

  // Combine priority and enable, write result into table
  // Note: bit 1 is RES1
  table[(ID - 8192)] = (0x2 | enable | priority);
  __dsb();

  return 0;
}

// ------------------------------------------------------------
// ITS setup functions
// ------------------------------------------------------------

uint32_t itsSharedTableSupport(void)
{
  return ((gic_its->GITS_TYPER >> 41) & 0x3);
}

// ------------------------------------------------------------

uint32_t itsGetAffinity(void)
{
  return gic_its->GITS_MPIDR;
} 

// ------------------------------------------------------------
// vSGI
// ------------------------------------------------------------

void itsSendSGI(uint32_t vintid, uint32_t vpeid)
{
  gic_its_sgi->GITS_SGIR = (uint64_t)(vintid & 0xF) | ((uint64_t)(vpeid & 0xFF) << 32);

  return;
}

// ------------------------------------------------------------
// ITS commands
// ------------------------------------------------------------

void itsVMAPP(uint32_t vpeid, uint32_t target, uint64_t conf_addr, uint64_t pend_addr, uint32_t alloc, uint32_t v, uint32_t doorbell, uint32_t size)
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
  command[0]   = 0x29;
  command[1]   = alloc | 0x2;  // Assume that memory is zeroed, so PTZ=1

  command[2]   = (uint8_t)(0xFF & (conf_addr >> 16));
  command[3]   = (uint8_t)(0xFF & (conf_addr >> 24));
  command[4]   = (uint8_t)(0xFF & (conf_addr >> 32));
  command[5]   = (uint8_t)(0xFF & (conf_addr >> 40));
  command[6]   = (uint8_t)(0xFF & (conf_addr >> 48));
  //command[7]

  command[8]   = (uint8_t)(0xFF & doorbell);
  command[9]   = (uint8_t)(0xFF & (doorbell >> 8));
  command[10]  = (uint8_t)(0xFF & (doorbell >> 16));
  command[11]  = (uint8_t)(0xFF & (doorbell >> 24));

  command[12]  = (uint8_t)(0xFF & vpeid);
  command[13]  = (uint8_t)(0xFF & (vpeid >> 8));
  //command[14]
  //command[15]

  //command[16]
  //command[17]
  command[18] = (uint8_t)(0xFF & target);
  command[19] = (uint8_t)(0xFF & (target >> 8));
  command[20] = (uint8_t)(0xFF & (target >> 16));
  command[21] = (uint8_t)(0xFF & (target >> 24));
  //command[22]
  command[23]   = (uint8_t)(v << 7);
  
  command[24]   = size;
  //command[25]
  command[26]   = (uint8_t)(0xFF & (pend_addr >> 16));
  command[27]   = (uint8_t)(0xFF & (pend_addr >> 24));
  command[28]   = (uint8_t)(0xFF & (pend_addr >> 32));
  command[29]   = (uint8_t)(0xFF & (pend_addr >> 40));
  command[30]   = (uint8_t)(0xFF & (pend_addr >> 48));
  //command[31]

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

void itsVSYNC(uint32_t vpeid)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0x25;
  //command[1]
  //command[2]
  //command[3]
  //command[4]
  //command[5]
  //command[6]
  //command[7]

  //command[8]
  //command[9]
  //command[10]
  //command[11]

  command[12]  = (uint8_t)(0xFF & vpeid);
  command[13]  = (uint8_t)(0xFF & (vpeid >> 8));
  //command[14]
  //command[15]

  //command[16]
  //command[17]
  //command[18]
  //command[19]
  //command[20]
  //command[21]
  //command[22]
  //command[23]

  //ocmmand[24]
  //command[25]
  //command[26]
  //command[27]
  //command[28]
  //command[29]
  //command[30]
  //command[31]

  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

void itsVMAPTI(uint32_t DeviceID, uint32_t EventID, uint32_t doorbell, uint32_t vpeid, uint32_t vINTID)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0x2A;
  //command[1]
  //command[2]
  //command[3]

  command[4]    = (uint8_t)(0xFF & DeviceID);
  command[5]    = (uint8_t)(0xFF & (DeviceID >> 8));
  command[6]    = (uint8_t)(0xFF & (DeviceID >> 16));
  command[7]    = (uint8_t)(0xFF & (DeviceID >> 24));

  command[8]    = (uint8_t)(0xFF & EventID);
  command[9]    = (uint8_t)(0xFF & (EventID >> 8));
  command[10]   = (uint8_t)(0xFF & (EventID >> 16));
  command[11]   = (uint8_t)(0xFF & (EventID >> 24));

  command[12]   = (uint8_t)(0xFF & vpeid);
  command[13]   = (uint8_t)(0xFF & (vpeid >> 8));
  //command[14]
  //command[15]

  command[16]   = (uint8_t)(0xFF & vINTID);
  command[17]   = (uint8_t)(0xFF & (vINTID >> 8));
  command[18]   = (uint8_t)(0xFF & (vINTID >> 16));
  command[19]   = (uint8_t)(0xFF & (vINTID >> 24));

  command[20]   = (uint8_t)(0xFF & doorbell);
  command[21]   = (uint8_t)(0xFF & (doorbell >> 8));
  command[22]   = (uint8_t)(0xFF & (doorbell >> 16));
  command[23]   = (uint8_t)(0xFF & (doorbell >> 24));

 
  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

void itsINVDB(uint32_t vpeid)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0x2E;

  //command[1]
  //command[2]
  //command[3]

  //command[4]
  //command[5]
  //command[6]
  //command[7]

  //command[8]
  //command[9]
  //command[10]
  //command[11]

  command[12]   = (uint8_t)(0xFF & vpeid);
  command[13]   = (uint8_t)(0xFF & (vpeid >> 8));
  //command[14]
  //command[15]


  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------

void itsVSGI(uint32_t vpeid, uint32_t vintid, uint32_t enable, uint32_t priority, uint32_t group, uint32_t clear)
{
  uint8_t command[32];
  uint32_t i;

  // Fill command with 0s
  for (i=0; i<32; i++)
    command[i] = 0;

  // Construct command
  command[0]   = 0x23;

  if (clear==0)
    command[1]  = (uint8_t)(enable | (group << 2));
  else
    command[1]  = 0x2;
  command[2]    = (uint8_t)(0xF0 & priority);
  //command[3]

  command[4]    = vintid;
  //command[5]
  //command[6]
  //command[7]

  //command[8]
  //command[9]
  //command[10]
  //command[11]

  command[12]   = (uint8_t)(0xFF & vpeid);
  command[13]   = (uint8_t)(0xFF & (vpeid >> 8));
  //command[14]
  //command[15]


  // Add command to queue
  itsAddCommand(command);

  return;
}

// ------------------------------------------------------------
// End of giv3_virt.c
// ------------------------------------------------------------
