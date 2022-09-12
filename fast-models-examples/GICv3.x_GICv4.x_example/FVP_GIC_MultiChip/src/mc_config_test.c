//
// Copyright (C) Arm Limited, 2019 All rights reserved.
//
// ------------------------------------------------------------

#include <stdio.h>
#include "assert.h"
#include "gicv3_basic.h"
#include "gicv3_registers.h"
#include "generic_timer.h"
#include "system_counter.h"
#include "sp804_timer.h"
#include "cpuid.h"
#include "multichip_basic.h"

// --------------------------------------------------------
static struct GICv3AddressWrapper *gic[MAX_NUM_CHIPS];
static uint32_t                    rd [MAX_NUM_CHIPS]; 
// --------------------------------------------------------

void MultiChipTest(unsigned master_id)
{
  //! 1. Initial Table set up
  printf("Checking Routing Table consistency after initial conditions...\n");
  bool should_be_true = cmpMultiRegs(master_id, gic);
  assert(should_be_true);
  printf("SUCCESS\n");

  //! 2 Change master id from 0 to 1
  printf("Switching MASTER GIC from %d ", master_id);
  master_id = 1;
  printf(" to %d\n", master_id);
  should_be_true = (master_id < NUM_GICS);
  assert(should_be_true);
  should_be_true = (gic[master_id]->setMultiChipOwner(&gic[master_id]) == 0);
  assert(should_be_true);

  printf("Switched owner\n");
  should_be_true = (cmpMultiRegs(master_id, gic));
  assert(should_be_true);
  printf("SUCCESS");

  //! 3.Master id 1 deletes gics 3, 4 and 5
  int delGicID[3] = {3, 4, 5};
  printf("Master Gic %d Deleting gics ", master_id);
  for (int i = 0; i < sizeof(delGicID) / sizeof(delGicID[0]); i++)
  {
    printf("%d ", delGicID[i]);
  }
  printf("\n");

  for (int i = 0; i < sizeof(delGicID) / sizeof(delGicID[0]); i++)
  {
    should_be_true = (gic[master_id]->disableGIC(&gic[master_id], delGicID[i]) == 0);
    assert(should_be_true);
  }
  should_be_true = (cmpMultiRegs(master_id, gic));
  assert(should_be_true);

  return;
}

int main(void)
{
  unsigned master_id = 0;
  initMultiChip(master_id, gic, rd);

  // //////////////////////////////
  MultiChipTest(master_id);

  // Always enable the Group enables after Multichip configuration (and its testing) is finished.
  for (unsigned gicID = 0; gicID < NUM_GICS; gicID++)
    gic[gicID]->enableGrp0Grp1(gic);

  for (unsigned i = 0; i < NUM_GICS; i++)
  {
    DeallocGIC(gic[i]);
  }

  printf("Main(): Test end\n");

  return 0;
}
