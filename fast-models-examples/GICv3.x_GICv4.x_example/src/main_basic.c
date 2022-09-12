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
#include "generic_timer.h"
#include "system_counter.h"
#include "sp804_timer.h"

extern uint32_t getAffinity(void);

volatile unsigned int flag;

// --------------------------------------------------------

#define DIST_BASE_ADDR     (0x2F000000)
#define RD_BASE_ADDR       (0x2F100000)
#define SYS_CONT_BASE_ADDR (0x2A430000)
#define SP804_BASE_ADDR    (0x1C110000)

// --------------------------------------------------------

int main(void)
{
  uint64_t current_time;
  uint32_t rd, affinity;
  
  affinity = getAffinity();

  //
  // Configure the interrupt controller
  //
  // Set location of GIC
  setGICAddr((void*)DIST_BASE_ADDR, (void*)RD_BASE_ADDR);

  // Enable GIC
  enableGIC();

  // Get the ID of the Redistributor connected to this PE
  rd = getRedistID(getAffinity());

  // Mark this core as being active
  wakeUpRedist(rd);

  // Configure the CPU interface
  // This assumes that the SRE bits are already set
  setPriorityMask(0xFF);
  enableGroup0Ints();
  enableGroup1Ints();
  enableNSGroup1Ints();  // This call only works as example runs at EL3

  //
  // Configure interrupt sources
  //

  // Secure Physical Timer (INTID 29)
  setIntPriority(29, rd, 0);
  setIntGroup(29, rd, GICV3_GROUP0);
  enableInt(29, rd);

  // Non-secure EL1 Physical Timer (INTID 30)
  setIntPriority(30, rd, 0);
  setIntGroup(30, rd, GICV3_GROUP0);
  enableInt(30, rd);

  // SP804 Timer (INTID 34)
  setIntPriority(34, 0, 0);
  setIntGroup(34, 0, GICV3_GROUP0);
  setIntRoute(34, GICV3_ROUTE_MODE_COORDINATE, affinity);
  setIntType(34, 0, GICV3_CONFIG_LEVEL);
  enableInt(34, 0);

  // Note: RD argument not needed for SPIs

  //
  // Configure and enable the System Counter and Generic Time
  // Used to generate the two PPIs
  //
  setSystemCounterBaseAddr(SYS_CONT_BASE_ADDR);  // Address of the System Counter
  initSystemCounter(SYSTEM_COUNTER_CNTCR_nHDBG,
                    SYSTEM_COUNTER_CNTCR_FREQ0,
                    SYSTEM_COUNTER_CNTCR_nSCALE);

  // Configure the Secure Physical Timer
  // This uses the CVAL/comparator to set an absolute time for the timer to fire
  current_time = getPhysicalCount();
  setSEL1PhysicalCompValue(current_time + 10000);
  setSEL1PhysicalTimerCtrl(CNTPS_CTL_ENABLE);

  // Configure the Non-secure Physical Timer
  // This uses the TVAL/timer to fire the timer in X ticks
  setNSEL1PhysicalTimerValue(20000);
  setNSEL1PhysicalTimerCtrl(CNTP_CTL_ENABLE);

  //
  // Configure SP804 peripheral
  // Used to generate the SPI
  //

  // Configure the SP804 timer to generate an interrupt
  setTimerBaseAddress(SP804_BASE_ADDR);
  initTimer(0x1, SP804_SINGLESHOT, SP804_GENERATE_IRQ);
  startTimer();


  // NOTE:
  // This code assumes that the IRQ and FIQ exceptions
  // have been routed to the appropriate Exception level
  // and that the PSTATE masks are clear.  In this example
  // this is done in the startup.s file

  //
  // Spin until interrupt
  //
  while(flag < 3)
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
    case 29:
      setSEL1PhysicalTimerCtrl(0);  // Disable timer to clear interrupt
      printf("FIQ: Secure Physical Timer\n");
      break;
    case 30:
      setNSEL1PhysicalTimerCtrl(0);  // Disable timer to clear interrupt
      printf("FIQ: Non-secure EL1 Physical Timer\n");
      break;
    case 34:
      clearTimerIrq();
      printf("FIQ: SP804 timer\n");
      break;
    case 1023:
      printf("FIQ: Interrupt was spurious\n");
      return;
    default:
      printf("FIQ: Panic, unexpected INTID\n");
  }

  // Write EOIR to deactivate interrupt
  writeEOIGrp0(ID);

  flag++;
  return;
}
