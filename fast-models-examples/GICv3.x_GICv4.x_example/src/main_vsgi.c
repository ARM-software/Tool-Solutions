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
// is provided “as is”, without warranty of any kind, express or implied. In no
// event shall the authors or copyright holders be liable for any claim, damages
// or other liability, whether in action or contract, tort or otherwise, arising
// from, out of or in connection with the Software or the use of Software.
//
// ------------------------------------------------------------

#include <stdio.h>
#include <string.h>
#include "gicv3_basic.h"
#include "gicv3_lpis.h"
#include "gicv4_virt.h"



extern uint32_t getAffinity(void);
uint32_t initGIC(void);
uint32_t checkGICModel(void);

volatile unsigned int flag;

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

  //
  // Configure the interrupt controller
  //
  rd0 = initGIC();
  
  // The example sends the vLPI to 0.0.0.1, so we also need its RD number
  rd1 = getRedistID(0x00000001);

  //
  // Before we start, ensure the tables initially contain zeros
  //
  memset((void*)VCONFIG_TABLE, 0, 8192);
  memset((void*)VPENDING_TABLE, 0, 8192);

  //
  // Set up Redistributor structures used for LPIs
  //

  setLPIConfigTableAddr(rd0, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(rd0, PENDING0_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd0);
  
  setLPIConfigTableAddr(rd1, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(rd1, PENDING1_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd1);

  setVPEConfTableAddr(rd0, VPE_TABLE, 0 /*attributes*/, 1 /*num_pages*/);
  setVPEConfTableAddr(rd1, VPE_TABLE, 0 /*attributes*/, 1 /*num_pages*/);


  //
  // Configure default doorbell, which is a physical LPI
  //

  configureLPI(rd0, 8192 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);   // We'll use this as a Default Doorbell


  //
  // Configure ITS
  //

  setITSBaseAddress((void*)ITS_BASE_ADDR);
  setSGIBaseAddr();
  
  // Check that the model has been launched with the correct configuration
  if (checkGICModel() != 0)
    return 1;

  // Allocated memory for the ITS command queue
  initITSCommandQueue(CMD_QUEUE, GICV3_ITS_CQUEUE_VALID /*Attributes*/, 1 /*num_pages*/);

  // Allocate Device table
  setITSTableAddr(0 /*index*/,
                  DEVICE_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);

  // Allocate Collection table
  setITSTableAddr(1 /*index*/,
                  COLLECTION_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);


  // Allocate vPE table
  setITSTableAddr(2 /*index*/,
                  VPE_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  1 /*num_pages*/);

  // NOTE: This example assumes that the following parameters are set on the Base Platform Model:
  // gic_distributor.GITS_BASER0-type=1
  // gic_distributor.GITS_BASER1-type=4
  // gic_distributor.GITS_BASER2-type=2

  // Enable the ITS
  enableITS();

  //
  // Create ITS mapping
  //

  // Get IDs in format used by ITS commands
  target_rd1 = getRdProcNumber(rd1);
  target_rd0 = getRdProcNumber(rd0);

  printf("main(): Creating vPEID 0, mapped to Redistributor 0.0.0.0\n");
  itsVMAPP(0 /*vpeid*/, target_rd0, VCONFIG_TABLE, VPENDING_TABLE, 1 /*alloc*/, 1 /*v*/, 8192 /*doorbell*/, 14 /*size*/);
  itsINVDB(0 /*vpeid*/);
  itsSYNC(target_rd0);
  itsVSYNC(0 /*vPEID*/);


  //
  // Configure vSGI
  //

  itsVSGI(0 /*vpeid*/, 0 /*vintid*/, 1 /*enable*/, 0 /*priority*/, 1 /*group*/, 0 /*clear*/);


  //
  // Generate interrupt
  //

  printf("main(): Sending vSGI 0 to vPEID 0\n");
  itsSendSGI(0 /*vintid*/, 0 /*vpeid*/);

  while(flag < 1)
  {}

  // Make vPE resident on RD1 (0.0.0.1)
  printf("main(): Making vPEID 0 resident on 0.0.0.1\nTest ends here\n");
  makeResident(rd1, 0 /*vpeid*/, 1 /*g0*/, 1 /*g1*/);

  // Semihosting halt will be called from 0.0.0.1
  while(1){}

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

uint32_t initGIC(void)
{
  uint32_t rd;

  // Set location of GIC
  setGICAddr((void*)0x2F000000 /*Distributor*/, (void*)0x2F100000 /*Redistributor*/);

  // Enable GIC
  enableGIC();

  // Get the ID of the Redistributor connected to this PE
  rd = getRedistID(getAffinity());

  // Mark this core as beign active
  wakeUpRedist(rd);

  // Configure the CPU interface
  // This assumes that the SRE bits are already set
  setPriorityMask(0xFF);
  enableGroup0Ints();
  enableGroup1Ints();
  enableNSGroup1Ints();  // This call only works as example runs at EL3

  return rd;
}

// --------------------------------------------------------

uint32_t checkGICModel(void)
{
  uint32_t type, entry_size;

  //
  // Check GICv4.1 is implemented
  //
  if (isGICv4x(0) != GICV3_v41)
  {
     printf("checkGICModel(): GITS_TYPER.{VLPIS,RVEPID}!={1,1}, GICv4.1 not supported\n");
     return 1;
  }


  //
  // Check vSGI is implemented
  //
  if (hasVSGI(0) == 0)
  {
     printf("checkGICModel(): GITS_TYPER.VSGI!=1 or GICR_TYPER.VSGI!=1, GICv4.1 vSGIs not supported\n");
     return 1;
  }

  //
  // Check the model used to identify RD's in ITS commands
  //
  if (getITSPTA() == 1)
  {
     printf("checkGICModel(): GITS_TYPER.PTA==1, this example expects PTA==0\n");
     return 1;
  }
  
  //
  // Check the GITS_BASER<n> types
  //
  getITSTableType(0 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_DEVICE)
  {
    printf("checkGICModel() - GITS_BASER0 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_DEVICE);
    return 1;
  }

  getITSTableType(1 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_COLLECTION)
  {
    printf("checkGICModel() - GITS_BASER1 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_COLLECTION);
    return 1;
  }

  getITSTableType(2 /*index*/, &type, &entry_size);
  if (type != GICV3_ITS_TABLE_TYPE_VIRTUAL)
  {
    printf("checkGICModel() - GITS_BASER2 not expected value (seeing 0x%x, expected 0x%x).\n", type, GICV3_ITS_TABLE_TYPE_VIRTUAL);
    return 1;
  }
  
  //
  // Check whether the ITS thinks it shares the vPE Configuration Table with the RDs
  // 
  if (itsSharedTableSupport() != 0x2)
  {
    printf("checkGICModel() - GITS_TYPER.SVE not expected value (seeing 0x%x, expected 0x2).\n", itsSharedTableSupport());
    return 1;
  }
  
  //
  // Check the CommonLPIAff group the ITS believes it shares the table with
  //
  if (itsGetAffinity() !=0)
  {
    printf("checkGICModel() - GITS_MPIDR does not report 0x0\n");
    return 1;
  }

  return 0;
}
