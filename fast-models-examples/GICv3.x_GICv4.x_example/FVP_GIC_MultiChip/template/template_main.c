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

void Test(unsigned master_id)
{
    // TODO perform test here
    return;
}

int main(void)
{
    unsigned master_id = 0;
    initMultiChip(master_id, gic, rd);
    // Test-specifc initialization done (e.g. enable LPIs, ITSs, ...)

    // //////////////////////////////
    MultiChipTest(master_id);
    // activateInterrupts(DIST_BASE_ADDR[0], RD_BASE_ADDR[0], 0);

    for (unsigned i = 0; i < NUM_GICS; i++)
    {
        DeallocGIC(gic[i]);
    }

    printf("Main(): Test end\n");

    return 0;
}
