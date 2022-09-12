//
// Copyright (C) Arm Limited, 2019 All rights reserved.
//
// ------------------------------------------------------------

#include <stdio.h>
#include "assert.h"
#include "gicv3_basic.h"
#include "gicv3_registers.h"
#include "gicv3_lpis.h"
#include "generic_timer.h"
#include "system_counter.h"
#include "sp804_timer.h"
#include "cpuid.h"
#include "multichip_basic.h"
#include "gic_constants.h"

// --------------------------------------------------------
static struct GICv3AddressWrapper *gic[MAX_NUM_CHIPS];
static uint32_t                    rd [MAX_NUM_CHIPS];

struct GICv3_its_ctlr_if*          mc_gic_its[MAX_NUM_CHIPS];
struct GICv3_its_int_if*           mc_gic_its_ints[MAX_NUM_CHIPS];

extern volatile unsigned int flag;
// --------------------------------------------------------

uint32_t getNewDeviceId()
{
    static uint32_t device_id = 0;
    return device_id++;
}

uint32_t getNewEventId()
{
    static uint32_t event_id = 0;
    return event_id++;
}

uint32_t getNewLpiId()
{
    static unsigned int lpi_id = 8193;
    return lpi_id++;
}

static const uint32_t DEVICE_ID_BIT_WIDTH = 16;

uint32_t MultichipLPI_CMD_Test_MOVI(uint8_t scenario_id,
                                    struct GICv3_its_ctlr_if* its0, uint32_t itt0, uint32_t target_rd0,
                                    struct GICv3_its_ctlr_if* its1, uint32_t itt1, uint32_t target_rd1,
                                    struct GICv3_its_ctlr_if* its2, uint32_t itt2, uint32_t target_rd2,
                                    struct GICv3_rdist_if** gic_rdist0_if, struct GICv3_rdist_if** gic_rdist1_if);

uint32_t MultichipLPI_CMD_Test_MOVALL(uint8_t scenario_id,
                                      struct GICv3_its_ctlr_if* its0, uint32_t itt0, uint32_t target_rd0,
                                      struct GICv3_its_ctlr_if* its1, uint32_t itt1, uint32_t target_rd1,
                                      struct GICv3_its_ctlr_if* its2, uint32_t itt2, uint32_t target_rd2,
                                      struct GICv3_rdist_if** gic_rdist0_if, struct GICv3_rdist_if** gic_rdist1_if);

uint32_t MultichipLPI_CMD_Test(unsigned master_id)
{
    // NOTE: For now in this test framework the .axf file, which programmes the GICs and services the interrupts,
    // is executed on the CPU affinity 0.0.0.0. Therefore, to test the multichip ITS commands, configure the LPIs
    // on the redistributor connected to the affinity 0.0.0.1, set mappings on the ITS of the GIC that owns that
    // redistributor, and issue the multichip ITS commands on that same ITS, such that the DST_TARGET of the
    // multiuchip ITS commands is the redistributor at 0.0.0.0. The software should verify the multichip update
    // and handle the moved LPI if was pending.

    // Therefore for now make sure that master_id is the chip 0
    assert(master_id == 0);

    struct GICv3_its_ctlr_if* its0 = mc_gic_its[master_id];  // The single ITS of the chip of ID master_id
    struct GICv3_its_ctlr_if* its1 = mc_gic_its[master_id+1];// The single ITS of the chip of ID master_id+1
    struct GICv3_its_ctlr_if* its2 = mc_gic_its[master_id+2];// The single ITS of the chip of ID master_id+2

    const uint32_t itt0 = INTERRUPT_TRANSLATION_TABLE[master_id];  // The single ITT of the chip of ID master_id
    const uint32_t itt1 = INTERRUPT_TRANSLATION_TABLE[master_id+1];// The single ITT of the chip of ID master_id+1
    const uint32_t itt2 = INTERRUPT_TRANSLATION_TABLE[master_id+2];// The single ITT of the chip of ID master_id+2

    // In multichip operation, need to format the 32-bit target values as ChipID at bits [31:2] and CoreID at bits [1:0]
    const uint32_t target_rd0 = ( (uint32_t)(master_id  ) << CORE_FIELD_WIDTH) | getRdProcNumber(&gic[master_id]  ->gic_rdist, rd[master_id]);  // The single rd of the chip of ID master_id
    const uint32_t target_rd1 = ( (uint32_t)(master_id+1) << CORE_FIELD_WIDTH) | getRdProcNumber(&gic[master_id+1]->gic_rdist, rd[master_id+1]);// The single rd of the chip of ID master_id+1
    const uint32_t target_rd2 = ( (uint32_t)(master_id+2) << CORE_FIELD_WIDTH) | getRdProcNumber(&gic[master_id+2]->gic_rdist, rd[master_id+2]);// The single rd of the chip of ID master_id+2

    struct GICv3_rdist_if** gic_rdist0_if = &gic[master_id  ]->gic_rdist;
    struct GICv3_rdist_if** gic_rdist1_if = &gic[master_id+1]->gic_rdist;

    unsigned scenario_id;

    for (scenario_id = 1; scenario_id <= 4; scenario_id++)
    {
        uint32_t result = MultichipLPI_CMD_Test_MOVI(scenario_id, its0, itt0, target_rd0,
                                                                  its1, itt1, target_rd1,
                                                                  its2, itt2, target_rd2,
                                                                  gic_rdist0_if, gic_rdist1_if);
        assert(result == 0);
    }

    for (scenario_id = 1; scenario_id <= 4; scenario_id++)
    {
        uint32_t result = MultichipLPI_CMD_Test_MOVALL(scenario_id, its0, itt0, target_rd0,
                                                                    its1, itt1, target_rd1,
                                                                    its2, itt2, target_rd2,
                                                                    gic_rdist0_if, gic_rdist1_if);
        assert(result == 0);
    }

    return 0;
}

uint32_t MultichipLPI_CMD_Test_MOVI(uint8_t scenario_id,
                                    struct GICv3_its_ctlr_if* its0, uint32_t itt0, uint32_t target_rd0,
                                    struct GICv3_its_ctlr_if* its1, uint32_t itt1, uint32_t target_rd1,
                                    struct GICv3_its_ctlr_if* its2, uint32_t itt2, uint32_t target_rd2,
                                    struct GICv3_rdist_if** gic_rdist0_if, struct GICv3_rdist_if** gic_rdist1_if)
{
    flag = 0; // reset the acknowledged interrupts counter. CAUTION! This is global for the test application.
    uint32_t device_id; // To hold a new device_id for a test case
    uint32_t event_id;  // To hold a new event_id  for a test case
    uint32_t lpi_id;    // To hold a new lpi_id    for a test case

    printf("\nTESTING ITS CMD MOVI scenario C%d\n", scenario_id);
    switch (scenario_id)
    {
        case 2:

            /////////////////////////////////////// Scenario C2 ///////////////////////////////////////
            ///////////// ITS of CHIP-A is commanded to move an LPI from CHIP-A to CHIP-B /////////////
            ///////////// CHIP-B should set the LPI.                                      /////////////
            ///////////// Below: CHIP-A == CHIP1, CHIP-B == CHIP0                         /////////////
            ///////////////////////////////////////////////////////////////////////////////////////////

            device_id = getNewDeviceId();
            event_id  = getNewEventId();
            lpi_id    = getNewLpiId();

            //
            // Create mappings at ITS1, the single ITS of GIC1 (chip of ID master_id+1): 4 STEPS
            //

            printf("Creating mappings at ITS1 (GIC1)\n");
            // STEP1: Let ITS1 hold mapping for some DeviceID
            itsMAPD (its1, device_id, /*addr of ITT*/ itt1 , DEVICE_ID_BIT_WIDTH);  // Map a DeviceID to a ITT
            // STEP2: Define some EventIDs for DeviceID, assign each EventID a special interrupt ID and map it to some Collection
            itsMAPTI(its1, device_id, event_id, lpi_id, /*collection*/ 1);          // Map an EventID to an INTID and collection (DeviceID specific)
            // STEP3: Map Collections to Redistributors
            itsMAPC (its1, /*target Redistributor*/ target_rd1, /*collection*/ 1);  // On ITS1, map Collection 1 to Redistributor 1 (rd0 of GIC1)
            itsMAPC (its1, /*target Redistributor*/ target_rd0, /*collection*/ 0);  // On ITS1, map Collection 0 to Redistributor 0 (rd0 of GIC0)
            // STEP4 Sync the changes
            itsSYNC (its1, /*target Redistributor*/ target_rd1);                    // Sync the changes

            //
            // Configure the LPI on GIC1 (chip of ID master_id+1)
            //

            printf("Configuring LPI %d on Redistributor 1 (rd0 of GIC1)\n", lpi_id);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id, GICV3_LPI_ENABLE, /*Priority*/ 0);

            //
            // Generate the LPI on GIC1 (chip of ID master_id+1) to cause it to pend
            //

            // The CPU interface's Group Enables are not enabled at the Redistributor1. This will not activate
            // the LPI when it gets pending, which is desired.
            printf("Sending LPI %d to ITS1 (GIC1)\n", lpi_id);
            itsINV(its1, device_id, event_id);
            itsINT(its1, device_id, event_id);

            //
            // Issue a multichip command at ITS1
            //

            // Issue a MOVI to make the target for (DeviceID,EventID) [intid lpi_id] become Redistributor 0 instead.
            // But first configure the LPI at the DST target such that it has known configuration when it is moved.
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id, GICV3_LPI_ENABLE, /*Priority*/ 0);
            printf("Issuing MOVI to redirect LPI %d to Redistributor 0 (GIC0)\n", lpi_id);
            itsMOVI (its1, device_id, event_id, /*collection*/ 0);                  // On ITS1, issue a MOVI command
            itsSYNC (its1, /*target Redistributor*/ target_rd1);                    // Sync the changes

            //
            // Spin until interrupt is observed on this executable, running on CPU 0.0.0.0 connected to Redistributor 0
            //
            while(flag < 1)
            {}

            break;

        case 4:

            /////////////////////////////////////// Scenario C4 ///////////////////////////////////////
            ///////////// ITS of CHIP-A is commanded to move an LPI from a Redistributor  /////////////
            ///////////// on CHIP-B to another Redistributor on CHIP-C.                   /////////////
            ///////////// CHIP-B should should forward the MOVI to CHIP-C which will apply/////////////
            ///////////// it locally.                                                     /////////////
            ///////////// Below: CHIP-A == CHIP2, CHIP-B == CHIP1, CHIP-C == CHIP0        /////////////
            ///////////////////////////////////////////////////////////////////////////////////////////

            device_id = getNewDeviceId();
            event_id  = getNewEventId();
            lpi_id    = getNewLpiId();

            //
            // Create mappings at ITS1, the single ITS of GIC1 (chip of ID master_id+1): 4 STEPS
            //

            printf("Creating mappings at ITS1 (GIC1)\n");
            // STEP1: Let ITS1 hold mapping for some DeviceID
            itsMAPD (its1, device_id, /*addr of ITT*/ itt1 , DEVICE_ID_BIT_WIDTH);  // Map a DeviceID to a ITT
            // STEP2: Define some EventIDs for DeviceID, assign each EventID a special interrupt ID and map it to some Collection
            itsMAPTI(its1, device_id, event_id, lpi_id, /*collection*/ 1);          // Map an EventID to an INTID and collection (DeviceID specific)
            // STEP3: Map Collections to Redistributors
            itsMAPC (its1, /*target Redistributor*/ target_rd1, /*collection*/ 1);  // On ITS1, map Collection 1 to Redistributor 1 (rd0 of GIC1)
            itsMAPC (its1, /*target Redistributor*/ target_rd0, /*collection*/ 0);  // On ITS1, map Collection 0 to Redistributor 0 (rd0 of GIC0)
            // STEP4 Sync the changes
            itsSYNC (its1, /*target Redistributor*/ target_rd1);                    // Sync the changes

            //
            // Also create mappings at ITS2, the single ITS of GIC2 (chip of ID master_id+2): 4 STEPS
            //

            printf("Creating mappings at ITS2 (GIC2)\n");
            // STEP1: Let ITS2 hold mapping for the same DeviceID
            itsMAPD (its2, device_id, /*addr of ITT*/ itt2 , DEVICE_ID_BIT_WIDTH);  // Map a DeviceID to a ITT
            // STEP2: Define the same EventIDs for DeviceID as above
            itsMAPTI(its2, device_id, event_id, lpi_id, /*collection*/ 1);          // Map an EventID to an INTID and collection (DeviceID specific)
            // STEP3: Map Collections to Redistributors
            itsMAPC (its2, /*target Redistributor*/ target_rd1, /*collection*/ 1);  // On ITS2, map Collection 1 to Redistributor 1 (rd0 of GIC1)
            itsMAPC (its2, /*target Redistributor*/ target_rd0, /*collection*/ 0);  // On ITS2, map Collection 0 to Redistributor 0 (rd0 of GIC0)
            // STEP4 Sync the changes
            itsSYNC (its2, /*target Redistributor*/ target_rd2);                    // Sync the changes

            //
            // Configure the LPI on GIC1 (chip of ID master_id+1)
            //

            printf("Configuring LPI %d on Redistributor 1 (rd0 of GIC1)\n", lpi_id);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id, GICV3_LPI_ENABLE, /*Priority*/ 0);

            //
            // Generate the LPI on GIC1 (chip of ID master_id+1) to cause it to pend
            //

            // The CPU interface's Group Enables are not enabled at the Redistributor1. This will not activate
            // the LPI when it gets pending, which is desired.
            printf("Sending LPI %d to ITS1 (GIC1)\n", lpi_id);
            itsINV(its1, device_id, event_id);
            itsINT(its1, device_id, event_id);

            //
            // Issue a multichip command at ITS1
            //

            // Issue a MOVI to make the target for (DeviceID,EventID) [intid lpi_id] become Redistributor 0 instead.
            // But first configure the LPI at the DST target such that it has known configuration when it is moved.
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id, GICV3_LPI_ENABLE, /*Priority*/ 0);
            printf("Issuing MOVI on ITS2 to redirect LPI %d from Redistributor 1 to Redistributor 0 (rd0 of GIC0)\n", lpi_id);
            itsMOVI (its2, device_id, event_id, /*collection*/ 0);                  // On ITS2, issue a MOVI command
            itsSYNC (its2, /*target Redistributor*/ target_rd2);                    // Sync the changes

            //
            // Spin until interrupt is observed on this executable, running on CPU 0.0.0.0 connected to Redistributor 0
            //
            while(flag < 1)
            {}

            break;

        case 1:
            /////////////////////////////////////// Scenario C1 ///////////////////////////////////////
            ///////////// ITS of CHIP-A is commanded to move an LPI from a Redistributor  /////////////
            ///////////// to another Redistributor on CHIP-A itself.                      /////////////
            ///////////// CHIP-A should apply the MOVI locally.                           /////////////
            ///////////// THIS SCENARIO IS NOT TESTED AS IT IS NOT MULTICHIP              /////////////
            ///////////////////////////////////////////////////////////////////////////////////////////
            printf("Nothing to do\n");
            break;

        case 3:
            /////////////////////////////////////// Scenario C3 ///////////////////////////////////////
            ///////////// ITS of CHIP-A is commanded to move an LPI from a Redistributor  /////////////
            ///////////// on CHIP-B to another Redistributor on CHIP-B itself.            /////////////
            ///////////// CHIP-B should apply the MOVI locally.                           /////////////
            ///////////// THIS SCENARIO IS NOT TESTED BECAUSE WE ASSUME ONE RD PER CHIP   /////////////
            ///////////////////////////////////////////////////////////////////////////////////////////
            printf("Nothing to do\n");
            break;

        default:
            printf("TEST SCENARIO NOT DEFINED!\n");
    }
    printf("        ###### TEST PASSED! ######\n");
    return 0;
}

uint32_t MultichipLPI_CMD_Test_MOVALL(uint8_t scenario_id,
                                      struct GICv3_its_ctlr_if* its0, uint32_t itt0, uint32_t target_rd0,
                                      struct GICv3_its_ctlr_if* its1, uint32_t itt1, uint32_t target_rd1,
                                      struct GICv3_its_ctlr_if* its2, uint32_t itt2, uint32_t target_rd2,
                                      struct GICv3_rdist_if** gic_rdist0_if, struct GICv3_rdist_if** gic_rdist1_if)
{
    flag = 0; // reset the acknowledged interrupts counter. CAUTION! This is global for the test application.
    uint32_t device_id; // To hold a new device_id for each test case
    uint32_t event_id0; // To hold a new event_id  for a test case
    uint32_t event_id1; // To hold a new event_id  for a test case
    uint32_t event_id2; // To hold a new event_id  for a test case
    uint32_t lpi_id0;   // To hold a new lpi_id    for a test case
    uint32_t lpi_id1;   // To hold a new lpi_id    for a test case
    uint32_t lpi_id2;   // To hold a new lpi_id    for a test case

    printf("\nTESTING ITS CMD MOVALL scenario C%d\n", scenario_id);
    switch (scenario_id)
    {
        case 2:

            /////////////////////////////////////// Scenario C2 ///////////////////////////////////////
            //////////// ITS of CHIP-A is commanded to move all LPIs from CHIP-A to CHIP-B ////////////
            //////////// CHIP-B should set the LPIs.                                        ////////////
            ////////////  Below: CHIP-A == CHIP1, CHIP-B == CHIP0                          ////////////
            ///////////////////////////////////////////////////////////////////////////////////////////

            device_id = getNewDeviceId();
            event_id0 = getNewEventId();
            event_id1 = getNewEventId();
            event_id2 = getNewEventId();
            lpi_id0   = getNewLpiId();
            lpi_id1   = getNewLpiId();
            lpi_id2   = getNewLpiId();

            //
            // Create mappings at ITS1, the single ITS of GIC1 (chip of ID master_id+1): 4 STEPS
            //

            printf("Creating mappings at ITS1 (GIC1)\n");
            // STEP1: Let ITS1 hold mapping for some DeviceID
            itsMAPD (its1, device_id, /*addr of ITT*/ itt1 , DEVICE_ID_BIT_WIDTH);   // Map a DeviceID to a ITT
            // STEP2: Define some EventIDs for the DeviceID, assign each EventID a special interrupt ID and map it to some Collection
            itsMAPTI(its1, device_id, event_id0, lpi_id0, /*collection*/ 1);         // Map an EventID to an INTID and collection (DeviceID specific)
            itsMAPTI(its1, device_id, event_id1, lpi_id1, /*collection*/ 1);         // Map an EventID to an INTID and collection (DeviceID specific)
            itsMAPTI(its1, device_id, event_id2, lpi_id2, /*collection*/ 1);         // Map an EventID to an INTID and collection (DeviceID specific)
            // STEP3: Map Collections to Redistributors
            itsMAPC (its1, /*target Redistributor*/ target_rd1, /*collection*/ 1);   // On ITS1, map Collection 1 to Redistributor 1 (rd0 of GIC1)
            itsMAPC (its1, /*target Redistributor*/ target_rd0, /*collection*/ 0);   // On ITS1, map Collection 0 to Redistributor 0 (rd0 of GIC0)
            // STEP4 Sync the changes
            itsSYNC (its1, /*target Redistributor*/ target_rd1);                     // Sync the changes

            //
            // Configure the LPIs on GIC1 (chip of ID master_id+1)
            //

            printf("Configuring LPIs %d, %d, %d on Redistributor 1 (rd0 of GIC1)\n", lpi_id0, lpi_id1, lpi_id2);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id0, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id1, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id2, GICV3_LPI_ENABLE, /*Priority*/ 0);

            //
            // Generate the LPIs on GIC1 (chip of ID master_id+1) to cause it to pend
            //

            // The CPU interface's Group Enables are not enabled at the Redistributor1. This will not activate
            // the LPI when it gets pending, which is desired.
            printf("Sending LPIs  %d, %d, %d to ITS1 (GIC1)\n", lpi_id0, lpi_id1, lpi_id2);
            itsINV(its1, device_id, event_id0);
            itsINT(its1, device_id, event_id0);
            itsINV(its1, device_id, event_id1);
            itsINT(its1, device_id, event_id1);
            itsINV(its1, device_id, event_id2);
            itsINT(its1, device_id, event_id2);

            //
            // Issue a multichip command at ITS1
            //

            // Issue a MOVALL to make the target for all (DeviceID,EventIDs) [intid lpi_id0, lpi_id1, lpi_id2] become Redistributor 0 instead.
            // But first configure the LPIs at the DST target such that they have known configuration when they are moved.
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id0, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id1, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id2, GICV3_LPI_ENABLE, /*Priority*/ 0);
            printf("Issuing MOVALL to redirect LPIs from Redistributor 1 (rd0 of GIC1) to Redistributor 0 (rd0 of GIC0)\n");
            itsMOVALL(its1, /*source_rd*/ target_rd1, /*target_rd*/ target_rd0);            // On ITS1, issue a MOVALL command
            itsSYNC  (its1, /*target Redistributor*/ target_rd1);                           // Sync the changes

            //
            // Spin until interrupts are observed on this executable, running on CPU 0.0.0.0 connected to Redistributor 0
            //
            while(flag < 3)
            {}

            break;

        case 4:

            /////////////////////////////////////// Scenario C4 ///////////////////////////////////////
            //////////// ITS of CHIP-A is commanded to move all LPIs from a Redistributor /////////////
            //////////// on CHIP-B to another Redistributor on CHIP-C.                     ////////////
            //////////// CHIP-B should should forward the MOVALL to CHIP-C which will apply////////////
            //////////// it locally.                                                       ////////////
            //////////// Below: CHIP-A == CHIP2, CHIP-B == CHIP1, CHIP-C == CHIP0          ////////////
            ///////////////////////////////////////////////////////////////////////////////////////////

            device_id = getNewDeviceId();
            event_id0 = getNewEventId();
            event_id1 = getNewEventId();
            event_id2 = getNewEventId();
            lpi_id0   = getNewLpiId();
            lpi_id1   = getNewLpiId();
            lpi_id2   = getNewLpiId();

            //
            // Create mappings at ITS1, the single ITS of GIC1 (chip of ID master_id+1): 4 STEPS
            //

            printf("Creating mappings at ITS1 (GIC1)\n");
            // STEP1: Let ITS1 hold mapping for some DeviceID
            itsMAPD (its1, device_id, /*addr of ITT*/ itt1 , DEVICE_ID_BIT_WIDTH);  // Map a DeviceID to a ITT
            // STEP2: Define some EventIDs for DeviceID, assign each EventID a special interrupt ID and map it to some Collection
            itsMAPTI(its1, device_id, event_id0, lpi_id0, /*collection*/ 1);        // Map an EventID to an INTID and collection (DeviceID specific)
            itsMAPTI(its1, device_id, event_id1, lpi_id1, /*collection*/ 1);        // Map an EventID to an INTID and collection (DeviceID specific)
            itsMAPTI(its1, device_id, event_id2, lpi_id2, /*collection*/ 1);        // Map an EventID to an INTID and collection (DeviceID specific)
            // STEP3: Map Collections to Redistributors
            itsMAPC (its1, /*target Redistributor*/ target_rd1, /*collection*/ 1);  // On ITS1, map Collection 1 to Redistributor 1 (rd0 of GIC1)
            itsMAPC (its1, /*target Redistributor*/ target_rd0, /*collection*/ 0);  // On ITS1, map Collection 0 to Redistributor 0 (rd0 of GIC0)
            // STEP4 Sync the changes
            itsSYNC (its1, /*target Redistributor*/ target_rd1);                    // Sync the changes

            //
            // Also create mappings at ITS2, the single ITS of GIC2 (chip of ID master_id+2): 4 STEPS
            //

            printf("Creating mappings at ITS2 (GIC2)\n");
            // STEP1: Let ITS2 hold mapping for the same DeviceID
            itsMAPD (its2, device_id, /*addr of ITT*/ itt2 , DEVICE_ID_BIT_WIDTH);  // Map a DeviceID to a ITT
            // STEP2: Define the same EventIDs for the DeviceID as above
            itsMAPTI(its2, device_id, event_id0, lpi_id0, /*collection*/ 1);        // Map an EventID to an INTID and collection (DeviceID specific)
            itsMAPTI(its2, device_id, event_id1, lpi_id1, /*collection*/ 1);        // Map an EventID to an INTID and collection (DeviceID specific)
            itsMAPTI(its2, device_id, event_id2, lpi_id2, /*collection*/ 1);        // Map an EventID to an INTID and collection (DeviceID specific)
            // STEP3: Map Collections to Redistributors
            itsMAPC (its2, /*target Redistributor*/ target_rd1, /*collection*/ 1);  // On ITS2, map Collection 1 to Redistributor 1 (rd0 of GIC1)
            itsMAPC (its2, /*target Redistributor*/ target_rd0, /*collection*/ 0);  // On ITS2, map Collection 0 to Redistributor 0 (rd0 of GIC0)
            // STEP4 Sync the changes
            itsSYNC (its2, /*target Redistributor*/ target_rd2);                    // Sync the changes

            //
            // Configure the LPIs on GIC1 (chip of ID master_id+1)
            //

            printf("Configuring LPIs %d, %d, %d on Redistributor 1 (rd0 of GIC1)\n", lpi_id0, lpi_id1, lpi_id2);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id0, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id1, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist1_if, 0 /*only one rd in each GIC: the first*/, lpi_id2, GICV3_LPI_ENABLE, /*Priority*/ 0);

            //
            // Generate the LPIs on GIC1 (chip of ID master_id+1) to cause it to pend
            //

            // The CPU interface's Group Enables are not enabled at the Redistributor1. This will not activate
            // the LPI when it gets pending, which is desired.
            printf("Sending LPIs %d, %d, %d to ITS1 (GIC1)\n", lpi_id0, lpi_id1, lpi_id2);
            itsINV(its1, device_id, event_id0);
            itsINT(its1, device_id, event_id0);
            itsINV(its1, device_id, event_id1);
            itsINT(its1, device_id, event_id1);
            itsINV(its1, device_id, event_id2);
            itsINT(its1, device_id, event_id2);

            //
            // Issue a multichip command at ITS1
            //

            // Issue a MOVALL to make the target for all (DeviceID,EventIDs) [intid lpi_id0, lpi_id1, lpi_id2] become Redistributor 0 instead.
            // But first configure the LPIs at the DST target such that they have known configuration when they are moved.
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id0, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id1, GICV3_LPI_ENABLE, /*Priority*/ 0);
            configureLPI(gic_rdist0_if, 0 /*only one rd in each GIC: the first*/, lpi_id2, GICV3_LPI_ENABLE, /*Priority*/ 0);
            printf("Issuing MOVALL to redirect LPIs from Redistributor 1 (rd0 of GIC1) to Redistributor 0 (rd0 of GIC0)\n");
            itsMOVALL(its2, /*source_rd*/ target_rd1, /*target_rd*/ target_rd0);    // On ITS1, issue a MOVALL command
            itsSYNC  (its2, /*target Redistributor*/ target_rd2);                   // Sync the changes

            //
            // Spin until interrupt is observed on this executable, running on CPU 0.0.0.0 connected to Redistributor 0
            //
            while(flag < 3)
            {}

            break;

        case 1:
            printf("Nothing to do\n");
            break;

        case 3:
            printf("Nothing to do\n");
            break;

        default:
            printf("TEST SCENARIO NOT DEFINED!\n");
    }
    printf("        ###### TEST PASSED! ######\n");
    return 0;
}

int main(void)
{
    printf("\nMain(): Test start\n\n");
    unsigned master_id = 0;
    initMultiChip(master_id, gic, rd);
    // Test-specifc initialization done (e.g. enable LPIs, ITSs, ...)

    initMultiChipLPITables(gic);
    initMultiChipITSs(mc_gic_its, mc_gic_its_ints, rd);

    // Always enable the Group enables immediately after Multichip configuration (and its testing) is finished.
    for (unsigned gicID = 0; gicID < NUM_GICS; gicID++)
        gic[gicID]->enableGrp0Grp1(gic);

    MultichipLPI_CMD_Test(master_id);

    for (unsigned i = 0; i < NUM_GICS; i++)
    {
        DeallocGIC(gic[i]);
    }

    printf("\nMain(): Test end\n");

    return 0;
}
