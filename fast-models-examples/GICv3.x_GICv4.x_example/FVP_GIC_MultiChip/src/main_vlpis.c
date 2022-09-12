// GICv3 Physical LPI Example
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
#include "gicv3_basic.h"
#include "gicv3_lpis.h"
#include "gicv4_virt.h"



extern uint32_t getAffinity(void);
uint32_t initGIC(struct GICv3AddressWrapper **gic);
uint32_t checkGICModel(struct GICv3AddressWrapper *gic, struct GICv3_its_ctlr_if* gic_its);

volatile unsigned int flag;

// ------------------------------------------------------------
// Setting location of interfaces
// ------------------------------------------------------------

struct GICv3_its_ctlr_if*     gic_its;
struct GICv3_its_int_if*      gic_its_ints;

// --------------------------------------------------------

// These locations are based on the memory map of the Base Platform model

#define CONFIG_TABLE      (0x80020000)
#define PENDING0_TABLE    (0x80030000)
#define PENDING1_TABLE    (0x80040000)

#define CMD_QUEUE         (0x80050000)
#define DEVICE_TABLE      (0x80060000)
#define COLLECTION_TABLE  (0x80070000)

#define VPE_TABLE         (0x80080000)
#define VCONFIG_TABLE     (0x80090000)
#define VPENDING_TABLE    (0x800A0000)

#define ITT               (0x800B0000)

#define ITS_BASE_ADDR     (0x2F020000)

// --------------------------------------------------------

int main(void)
{
  uint32_t type, entry_size;
  uint32_t rd0, rd1, target_rd0, target_rd1;

  struct GICv3AddressWrapper *gic = allocGIC(0, DIST_BASE_ADDR0, RD_BASE_ADDR0, 10);

  //
  // Configure the interrupt controller
  //
  rd0 = initGIC(&gic);

  // The example sends the vLPI to 0.0.0.1, so we also needs its RD number
  rd1 = getRedistID(0x00000001);
  
  //
  // Set up Redistributor structures used for LPIs
  //

  setLPIConfigTableAddr(&gic->gic_rdist, rd0, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(&gic->gic_rdist, rd0, PENDING0_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd0);
  
  setLPIConfigTableAddr(&gic->gic_rdist, rd1, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(&gic->gic_rdist, rd1, PENDING1_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd1);

  setVPEConfTableAddr(&gic->gic_rdist, rd0, VPE_TABLE, 0 /*attributes*/, 1 /*num_pages*/);
  setVPEConfTableAddr(&gic->gic_rdist, rd1, VPE_TABLE, 0 /*attributes*/, 1 /*num_pages*/);


  //
  // Configure virtual interrupt
  //
  
  configureVLPI((uint8_t*)(VCONFIG_TABLE), 8192 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);

  //
  // Configure physical doorbell interrupt
  //

  configureLPI(&gic->gic_rdist, rd0, 8192 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);   // We'll use this as a Default Doorbell
  configureLPI(&gic->gic_rdist, rd0, 8193 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);   // This we'll use to verify command completion on the ITS

  //
  // Configure ITS
  //

  setITSBaseAddress(gic_its, gic_its_ints, (void*)ITS_BASE_ADDR);
  
  // Check that the model has been launched with the correct configuration
  if (checkGICModel(gic, gic_its) != 0)
    return 1;

  // Allocated memory for the ITS command queue
  initITSCommandQueue(gic_its, CMD_QUEUE, GICV3_ITS_CQUEUE_VALID /*Attributes*/, 1 /*num_pages*/);

  // Allocate Device table
  setITSTableAddr(gic_its,
                  0 /*index*/,
                  DEVICE_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);

  // Allocate Collection table
  setITSTableAddr(gic_its,
                  1 /*index*/,
                  COLLECTION_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);


  // Allocate vPE table
  setITSTableAddr(gic_its,
                  2 /*index*/,
                  VPE_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  1 /*num_pages*/);

  // NOTE: This example assumes that the following parameters are set on the Base Platform Model:
  // gic_distributor.GITS_BASER0-type=1
  // gic_distributor.GITS_BASER1-type=4
  // gic_distributor.GITS_BASER2-type=2

  // Enable the ITS
  enableITS(gic_its);
  
  //
  // Create ITS mapping
  //

  // Get IDs in format used by ITS commands
  target_rd1 = getRdProcNumber(&gic->gic_rdist, rd1);
  target_rd0 = getRdProcNumber(&gic->gic_rdist, rd0);

  // Set up a mapping
  itsMAPD(0 /*DeviceID*/, ITT /*addr of ITT*/, 2 /*bit width of ID*/);         // Map a DeviceID to a ITT
  
  itsVMAPP(gic_its, 0 /*vpeid*/, target_rd1, VCONFIG_TABLE, VPENDING_TABLE, 1 /*alloc*/, 1 /*v*/, 8192 /*doorbell*/, 14 /*size*/);
  itsINVDB(gic_its, 0 /*vpeid*/);
  itsVMAPTI(gic_its, 0 /*DeviceID*/, 0 /*EventID*/, 1023 /*doorbell*/, 0 /*vpeid*/, 8192 /*vINTID*/);
  //itsVSYNC(0 /*vpeid*/);


  itsMAPTI(gic_its, 0 /*DeviceID*/, 1 /*EventID*/, 8193 /*intid*/, 0 /*collection*/);   // Map an EventID to an INTD and collection (DeviceID specific)
  itsMAPC(gic_its, target_rd0, 0 /*collection*/);                                       // Map a Collection to a Redistributor
  itsSYNC(gic_its, target_rd0);                                                         // Sync the changes


  //
  // Generate interrupt
  //

  printf("main(): Sending pLPI to this core (0.0.0.0)\n");
  itsINV(gic_its, 0 /*DeviceID*/, 1 /*EventID*/);
  itsINT(gic_its, 0 /*DeviceID*/, 1 /*EventID*/);

  // Wait for interrupt
  while(flag < 1)
  {}

  // Make vPE resident on RD1 (0.0.0.1)
  makeResident(&gic->gic_rdist, rd1, 0 /*vpeid*/, 1 /*g0*/, 1 /*g1*/);

  printf("main(): Sending vLPI 8192 to vPEID 0, mapped to physical core 0.0.0.1\n");
  itsINV(gic_its, 0 /*DeviceID*/, 0 /*EventID*/);
  itsINT(gic_its, 0 /*DeviceID*/, 0 /*EventID*/);

  // Wait for interrupt
  while(flag < 2)
  {}

  // NOTE:
  // This code assumes that the IRQ and FIQ exceptions
  // have been routed to the appropriate Exception level
  // and that the PSTATE masks are clear.  In this example
  // this is done in the startup_vlpis.s file


  printf("main(): Test end\n");

  return 1;
}

// --------------------------------------------------------

void fiqHandler(void)
{
  uint32_t ID;
  uint32_t group = 0;

  // Read the IAR to get the INTID of the interrupt taken
  ID = readIARGrp0();

  printf("FIQ: Received INTID %d\n", ID);

  switch (ID)
  {
    case 1021:
      printf("FIQ: Received Non-secure interrupt from the ITS\n");
      ID = readIARGrp1();
      printf("FIQ: Read INTID %d from IAR1\n", ID);
      group = 1;
      break;
    case 1023:
      printf("FIQ: Interrupt was spurious\n");
      return;
    default:
      printf("FIQ: Panic, unexpected INTID\n");
  }

  // Write EOIR to deactivate interrupt
  if (group == 0)
    writeEOIGrp0(ID);
  else
    writeEOIGrp1(ID);

  flag++;
  return;
}

// --------------------------------------------------------

uint32_t initGIC(struct GICv3AddressWrapper **gic)
{
  uint32_t rd;

  // Set location of GIC
  (*gic)->setGICAddr(gic, (void*)((*gic)->distBaseAddress), (void*)((*gic)->RdistBaseAddress));

  // Enable GIC
  (*gic)->enableGIC(gic);

  // Get the ID of the Redistributor connected to this PE
  rd = (*gic)->getRedistID(gic, getAffinity());

  // Mark this core as beign active
  (*gic)->wakeUpRedist(gic, rd);

  // Configure the CPU interface
  // This assumes that the SRE bits are already set
  setPriorityMask(0xFF);
  enableGroup0Ints();
  enableGroup1Ints();
  enableNSGroup1Ints();  // This call only works as example runs at EL3

  return rd;
}

// --------------------------------------------------------

uint32_t checkGICModel(struct GICv3AddressWrapper *gic, struct GICv3_its_ctlr_if* gic_its)
{
  uint32_t type, entry_size;

  //
  // Check GICv4.1 is implemented
  //
  if (isGICv4x(&gic->gic_rdist) != GICV3_v41)
  {
     printf("checkGICModel(): GITS_TYPER.{VLPIS,RVEPID}!={1,1}, GICv4.1 not supported\n");
     return 1;
  }

  //
  // Check the model used to identify RD's in ITS commands
  //
  if (getITSPTA(gic_its) == 1)
  {
     printf("checkGICModel(): GITS_TYPER.PTA==1, this example expects PTA==0\n");
     return 1;
  }
  
  //
  // Check the GITS_BASER<n> types
  //
  getITSTableType(gic_its, 0 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_DEVICE)
  {
    printf("checkGICModel() - GITS_BASER0 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_DEVICE);
    return 1;
  }

  getITSTableType(gic_its, 1 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_COLLECTION)
  {
    printf("checkGICModel() - GITS_BASER1 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_COLLECTION);
    return 1;
  }

  getITSTableType(gic_its, 2 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_VIRTUAL)
  {
    printf("checkGICModel() - GITS_BASER2 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_VIRTUAL);
    return 1;
  }
  
  //
  // Check whether the ITS thinks it shares the vPE Configuration Table with the RDs
  // 
  if (itsSharedTableSupport(gic_its) != 0x2)
  {
    printf("checkGICModel() - GITS_TYPER.SVE not expected value (seeing 0x%x, expected 0x2).\n", itsSharedTableSupport());
    return 1;
  }
  
  //
  // Check the CommonLPIAff group the ITS believes it shares the table with
  //
  if (itsGetAffinity(gic_its) !=0)
  {
    printf("checkGICModel() - GITS_MPIDR does not report 0x0\n");
    return 1;
  }

  return 0;
}
