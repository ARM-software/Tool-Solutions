// Example of using the Generic Timer in AArch64
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

extern uint32_t getAffinity(void);
uint32_t initGIC(void);
uint32_t checkGICModel(void);

volatile unsigned int flag;

// --------------------------------------------------------

#define DIST_BASE_ADDR     (0x2F000000)
#define RD_BASE_ADDR       (0x2F100000)

// --------------------------------------------------------

int main(void)
{
  uint64_t current_time;
  uint32_t rd, affinity;
  
  affinity = getAffinity();

  //
  // Configure the interrupt controller
  //
  rd = initGIC();
  
  // Check that the model has been launched with the correct configuration
  if (checkGICModel() != 0)
    return 1;


  //
  // Configure interrupt sources
  //

  // GICv3.1 Extended PPI range (INTID 1056)
  setIntPriority(1056, rd, 0);
  setIntGroup(1056, rd, GICV3_GROUP0);
  enableInt(1056, rd);

  // GICv3.1 Extended SPI range (INTID 4096)
  setIntPriority(4096, 0, 0);
  setIntGroup(4096, 0, GICV3_GROUP0);
  setIntRoute(4096, GICV3_ROUTE_MODE_COORDINATE, affinity);
  setIntType(4096, 0, GICV3_CONFIG_EDGE);
  enableInt(4096, 0);


  //
  // Trigger PPI in GICv3.1 extended range
  //
  
  // Setting the interrupt as pending manually, as the
  // Base Platform model does not have a peripheral
  // connected within this range
  setIntPending(1056, rd);
  
  
  //
  // Trigger SPI in GICv3.1 extended range
  //
  
  // Setting the interrupt as pending manually, as the
  // Base Platform model does not have a peripheral
  // connected within this range
  setIntPending(4096, 0);

  // NOTE:
  // This code assumes that the IRQ and FIQ exceptions
  // have been routed to the appropriate Exception level
  // and that the PSTATE masks are clear.  In this example
  // this is done in the startup.s file

  //
  // Spin until interrupt
  //
  while(flag < 2)
  {}
  
  printf("Main(): Test end\n");

  return 1;
}

// --------------------------------------------------------

void fiqHandler(void)
{
  unsigned int ID;

  // Read the IAR to get the INTID of the interrupt taken
  ID = readIARGrp0();

  printf("FIQ: Received INTID %d\n", ID);

  switch (ID)
  {
    case 1023:
      printf("FIQ: Interrupt was spurious\n");
      return;
    case 1056:
      printf("FIQ: GICv3.1 extended PPI range interrupt\n");
      break;
    case 4096:
      printf("FIQ: GICv3.1 extended SPI range interrupt\n");
      // No need to clear the interrut, as we configured it as edge-triggered
      break;
    default:
      printf("FIQ: Panic, unexpected INTID\n");
  }

  // Write EOIR to deactivate interrupt
  writeEOIGrp0(ID);

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

uint32_t checkGICModel(void)
{
  // Check that the GICv3.1 extended PPI range is implemented
  if (getExtPPI(0) == 32)
  {
    printf("checkGICModel() - GICR_TYPER.PPInum reports no extended PPI support.\n");
    return 1;
  }

  // Check that the GICv3.1 extended SPI range is implemented
  if (getExtSPI() == 0)
  {
    printf("checkGICModel() - GICD_TYPER.ESPI reports no extended SPI support.\n");
    return 1;
  }

  return 0;
}

