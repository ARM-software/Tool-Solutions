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
#include "gicv3_basic.h"
#include "gicv3_lpis.h"

extern void sendLPI(uint32_t, uint32_t);

extern uint32_t getAffinity(void);
uint32_t initGIC(void);
uint32_t checkGICModel(void);

volatile unsigned int flag;

// --------------------------------------------------------

// These locations are based on the memory map of the Base Platform model

#define CONFIG_TABLE      (0x80020000)
#define PENDING_TABLE     (0x80030000)

#define CMD_QUEUE         (0x80040000)
#define DEVICE_TABLE      (0x80050000)
#define COLLECTION_TABLE  (0x80060000)

#define ITT               (0x80070000)

#define DIST_BASE_ADDR    (0x2F000000)
#define RD_BASE_ADDR      (0x2F100000)
#define ITS_BASE_ADDR     (0x2F020000)

// --------------------------------------------------------

int main(void)
{
  uint32_t type, entry_size;
  uint32_t rd, target_rd;

  //
  // Configure the interrupt controller
  //
  rd = initGIC();

  
  //
  // Set up Redistributor structures used for LPIs
  //

  setLPIConfigTableAddr(rd, CONFIG_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  setLPIPendingTableAddr(rd, PENDING_TABLE, GICV3_LPI_DEVICE_nGnRnE /*Attributes*/, 15 /* Number of ID bits */);
  enableLPIs(rd);

  //
  // Configure ITS
  //

  setITSBaseAddress((void*)ITS_BASE_ADDR);
  
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

  //Allocate Collection table
  setITSTableAddr(1 /*index*/,
                  COLLECTION_TABLE /* addr */,
                  (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE),
                  GICV3_ITS_TABLE_PAGE_SIZE_4K,
                  16 /*num_pages*/);

  // Enable the ITS
  enableITS();
  
  //
  // Create ITS mapping
  //

  if (getITSPTA() == 1)
  {
     printf("main(): GITS_TYPER.PTA==1, this example expects PTA==0\n");
     return 1;
  }
  target_rd = getRdProcNumber(rd);

  // Set up a mapping
  itsMAPD(0 /*DeviceID*/, ITT /*addr of ITT*/, 2 /*bit width of ID*/);         // Map a DeviceID to a ITT
  itsMAPTI(0 /*DeviceID*/, 0 /*EventID*/, 8193 /*intid*/, 0 /*collection*/);   // Map an EventID to an INTD and collection (DeviceID specific)
  itsMAPC(target_rd /* target Redistributor*/, 0 /*collection*/);              // Map a Collection to a Redistributor
  itsSYNC(target_rd /* target Redistributor*/);                                // Sync the changes

  //
  // Configure and generate an LPI
  //

  configureLPI(rd, 8193 /*INTID*/, GICV3_LPI_ENABLE, 0 /*Priority*/);
  printf("main(): Sending LPI 8193\n");
  itsINV(0 /*DeviceID*/, 0 /*EventID*/);
  itsINT(0 /*DeviceID*/, 0 /*EventID*/);


  // NOTE:
  // This code assumes that the IRQ and FIQ exceptions
  // have been routed to the appropriate Exception level
  // and that the PSTATE masks are clear.  In this example
  // this is done in the startup.s file

  //
  // Spin until interrupt
  //
  while(flag < 1)
  {}
  
  printf("Main(): Test end\n");

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
  setGICAddr((void*)DIST_BASE_ADDR, (void*)RD_BASE_ADDR);

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

//
// This function checks the model has been configured the way the example expects
//

uint32_t checkGICModel(void)
{
  uint32_t type, entry_size;

  //
  // Check that LPIs supported
  //
  if (getMaxLPI(0) == 0)
  {
     printf("checkGICModel(): Physical LPIs not supported\n");
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

  return 0;
}

