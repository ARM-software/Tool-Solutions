#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gicv3_basic.h"
#include "assert.h"
#include "gicv3_registers.h"
#include "gicv3_lpis.h"
#include "generic_timer.h"
#include "system_counter.h"
#include "sp804_timer.h"
#include "cpuid.h"
#include "multichip_basic.h"
#include "gic_constants.h"

// Compares multichip registers across all gics to ensure coherency.
bool cmpMultiRegs(unsigned master_id, struct GICv3AddressWrapper **gic)
{
    bool status = true;

    for (unsigned i = 0; i < NUM_GICS - 1; i++)
    {
        status &= gic[i]->gic_dist->GICD_DCHIPR == (master_id << 4);
        for (unsigned j = i + 1; j < NUM_GICS; j++)
        {
            if (((gic[i]->gic_dist->GICD_CHIPR[i] & 0x1) == 0) ||
                ((gic[j]->gic_dist->GICD_CHIPR[i] & 0x1) == 0))
            {
                // Do not compare offline chip
                continue;
            }
            status &= (gic[i]->gic_dist->GICD_CHIPR[i] == gic[j]->gic_dist->GICD_CHIPR[i]);
        }
    }

    for (unsigned i = 0; i < NUM_GICS; i++)
    {
        gic[i]->printState(&gic[i]);
    }

    return status;
}

// MultiChip GIC register initialization
uint32_t initMultiChip(unsigned master_id, struct GICv3AddressWrapper **gic, uint32_t *rd)
{
    /*Initialize GIC*/
    for (unsigned i = 0; i < NUM_GICS; i++)
    {
        gic[i] = allocGIC(i, DIST_BASE_ADDR[i], RD_BASE_ADDR[i], 1);
        initGIC(i, gic, rd);
        // Group enables must be disabled before any multichip configuration.
        // CAUTION! Remember to enable them after configuration is finished.
        gic[i]->disableGrp0Grp1(gic);
    }

    bool should_be_true = gic[master_id]->setMultiChipOwner(&gic[master_id]) == 0;
    assert(should_be_true);
    for (unsigned gIndex = 0; gIndex < NUM_GICS; gIndex++)
    {
        bool should_be_true = (gic[master_id]->configRoutingTable(&gic[master_id], &gic[gIndex]) == 0);
        assert(should_be_true);
    }
    return 0;
}

extern  uint32_t    getAffinity     (void);
volatile unsigned int flag;

void activateInterrupts(uint64_t distBase, uint64_t RdistBase, unsigned gicID, struct GICv3AddressWrapper **gic, uint32_t* rd)
{
    uint64_t current_time;
    uint32_t affinity;
    affinity = getAffinity();

    // Secure Physical Timer (INTID 29)
    gic[gicID]->setIntPriority(&gic[gicID], 29, rd[gicID], 0);
    gic[gicID]->setIntGroup(&gic[gicID], 29, rd[gicID], GICV3_GROUP0);
    gic[gicID]->enableInt(&gic[gicID], 29, rd[gicID]);

    // Non-secure EL1 Physical Timer (INTID 30)
    gic[gicID]->setIntPriority(&gic[gicID], 30, rd[gicID], 0);
    gic[gicID]->setIntGroup(&gic[gicID], 30, rd[gicID], GICV3_GROUP0);
    gic[gicID]->enableInt(&gic[gicID], 30, rd[gicID]);

    // GICv3.1 Extended PPI range (INTID 1056)
    gic[gicID]->setIntPriority(&gic[gicID], 1056, rd[gicID], 0);
    gic[gicID]->setIntGroup(&gic[gicID], 1056, rd[gicID], GICV3_GROUP0);
    gic[gicID]->enableInt(&gic[gicID], 1056, rd[gicID]);


    // SP804 Timer (INTID 34)
    gic[gicID]->setIntPriority(&gic[gicID], 34, 0, 0);
    gic[gicID]->setIntGroup(&gic[gicID], 34, 0, GICV3_GROUP0);
    gic[gicID]->setIntRoute(&gic[gicID], 34, GICV3_ROUTE_MODE_COORDINATE, affinity);
    gic[gicID]->setIntType(&gic[gicID], 4096, 0, GICV3_CONFIG_LEVEL);
    gic[gicID]->enableInt(&gic[gicID], 34, 0);

    // Note: RD argument not needed for SPIs

    // GICv3.1 Extended SPI range (INTID 4096)
    gic[gicID]->setIntPriority(&gic[gicID], 4096, 0, 0);
    gic[gicID]->setIntGroup(&gic[gicID], 4096, 0, GICV3_GROUP0);
    gic[gicID]->setIntRoute(&gic[gicID], 4096, GICV3_ROUTE_MODE_COORDINATE, affinity);
    gic[gicID]->setIntType(&gic[gicID], 4096, 0, GICV3_CONFIG_EDGE);
    gic[gicID]->enableInt(&gic[gicID], 4096, 0);

    // Configure and enable the System Counter and Generic Time
    // Used to generate the two PPIs
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

    // Configure SP804 peripheral
    // Used to generate the SPI
    // Configure the SP804 timer to generate an interrupt
    setTimerBaseAddress(SP804_BASE_ADDR);
    initTimer(0x1, SP804_SINGLESHOT, SP804_GENERATE_IRQ);
    startTimer();

    // Trigger PPI in GICv3.1 extended range
    // Setting the interrupt as pending manually, as the
    // Base Platform model does not have a peripheral
    // connected within this range
    gic[gicID]->setIntPending(&gic[gicID], 1056, rd[gicID]);
    gic[gicID]->setIntPending(&gic[gicID], 1056, rd[gicID]);

    // Trigger SPI in GICv3.1 extended range
    // Setting the interrupt as pending manually, as the
    // Base Platform model does not have a peripheral
    // connected within this range
    gic[gicID]->setIntPending(&gic[gicID], 4096, 0);

    // NOTE:
    // This code assumes that the IRQ and FIQ exceptions
    // have been routed to the appropriate Exception level
    // and that the PSTATE masks are clear.  In this example
    // this is done in the startup.s file

    // Spin until interrupt
    // wakeUpRedist
    printf("\n%d, %u\n", flag, GetCPUID());
    while(flag < 5)
    {
    }
  
    return;
}
void fiqHandler(void)
{
    unsigned int ID;
    bool group = 0;

    // Read the IAR to get the INTID of the interrupt taken
    ID = readIARGrp0();
    if (ID == 1021)
    {
        // Group1 interrupt
        group = 1;
        writeEOIGrp0(ID);
        ID = readIARGrp1();
    }

    printf("FIQ: Received INTID %d, CPUID: %u\n", ID, GetCPUID());

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
    case 1056:
        printf("FIQ: GICv3.1 extended PPI range interrupt\n");
        break;
    case 4096:
        printf("FIQ: GICv3.1 extended SPI range interrupt\n");
        // No need to clear the interrut, as we configured it as edge-triggered
        break;
    case 8192:
    case 8193:
    case 8194:
    case 8195:
        printf("FIQ: Type:LPI. Expected.\n");
        break;
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

// System register GIC Initialization
uint32_t initGIC(unsigned gicID, struct GICv3AddressWrapper **gic, uint32_t *rd)
{
    // Set location of GIC, Enable, get ID of redistributor
    gic[gicID]->setGICAddr(&gic[gicID], (void*)(gic[gicID]->distBaseAddress), (void*)(gic[gicID]->RdistBaseAddress));
    bool should_be_true = gic[gicID]->enableGIC(&gic[gicID]) == 0;
    assert(should_be_true);
    rd[gicID] = gic[gicID]->getRedistID(&gic[gicID], getAffinity());

    // Mark this core as being active
    should_be_true = (gic[gicID]->wakeUpRedist(&gic[gicID], rd[gicID]) == 0);
    assert(should_be_true);

    // Configure the CPU interface
    // This assumes that the SRE bits are already set
    setPriorityMask(0xFF);
    enableGroup0Ints();
    enableGroup1Ints();
    enableNSGroup1Ints();  // This call only works as example runs at EL3

    return 0;
}

uint32_t initMultiChipLPITables(struct GICv3AddressWrapper **gic)
{
    for (unsigned num = 0; num < NUM_GICS; ++num)
    {
        initLPITable(&gic[num]->gic_rdist, 0 /* only 1 RD for each GIC*/,
                     CONFIG_TABLE[num],  GICV3_LPI_DEVICE_nGnRnE /* Attributes : Strongly-ordered Device */, 15 /* Number of ID bits */,
                     PENDING_TABLE[num], GICV3_LPI_DEVICE_nGnRnE /* Attributes : Strongly-ordered Device */, 15 /* Number of ID bits */);
    }
    return 0;
}

void setITSTableAddrWithCheck(struct GICv3_its_ctlr_if* gic_its, unsigned gits_baser_index, uint8_t table_type, uint64_t addr, uint64_t attributes, uint32_t page_size, uint32_t num_pages)
{
    uint64_t tmp;

    uint8_t type_configured = (gic_its->GITS_BASER[gits_baser_index] >> 56) & 0x7;
    if (table_type != type_configured)
    {
        printf("[ERROR] GITS_BASER[%d].type mismatches between software(%d) and simulator(%d). Exit.\n",
               gits_baser_index, table_type, type_configured);
    }

    setITSTableAddr(gic_its, gits_baser_index, addr, attributes, page_size, num_pages);
}

// All the GICs in multi-chip should look the same from all the cores and software, so
// device/collection table in each memory region should also be the same.
// However, we should take care that the ownership of each LPI should belong to specific chip.
// So, from 8196, we will assign 1024 LPIs from GIC0 to GIC#NUM_GIC-1#.

uint32_t initMultiChipITSTable(unsigned gic_index, struct GICv3_its_ctlr_if* gic_its, struct GICv3_its_int_if* gic_its_int, uint32_t *rd)
{
    return 0;
}

uint32_t initMultiChipITS(unsigned gic_index, struct GICv3_its_ctlr_if* gic_its, struct GICv3_its_int_if* gic_its_int, uint32_t* rd)
{
    uint64_t page_table_attr = (GICV3_ITS_TABLE_PAGE_VALID | GICV3_ITS_TABLE_PAGE_DIRECT
                             | GICV3_ITS_TABLE_PAGE_DEVICE_nGnRnE);
    initITSCommandQueue(gic_its, COMMAND_QUEUE_TABLE[gic_index],
                        GICV3_ITS_CQUEUE_VALID /* Attributes */, 1 /* page num*/);

    // GITS_BASER.type is assumed to use the default value. If GITS_BASER[0-2].type are given differently, the index
    // field should be updated accordingly, and vice versa.
    setITSTableAddrWithCheck(gic_its,
                             0 /* GITS_BASER index */,
                             GICV3_ITS_TABLE_TYPE_DEVICE,
                             DEVICE_TABLE[gic_index] /* addr */,
                             page_table_attr,
                             GICV3_ITS_TABLE_PAGE_SIZE_4K,
                             16 /* num pages */);
    setITSTableAddrWithCheck(gic_its,
                             1 /* GITS_BASER index */,
                             GICV3_ITS_TABLE_TYPE_COLLECTION,
                             COLLECTION_TABLE[gic_index] /* addr */,
                             page_table_attr,
                             GICV3_ITS_TABLE_PAGE_SIZE_4K,
                             16 /* num pages */);
    setITSTableAddrWithCheck(gic_its,
                             2 /* GITS_BASER index */,
                             GICV3_ITS_TABLE_TYPE_VIRTUAL,
                             VPE_CONFIG_TABLE[gic_index] /* addr */,
                             page_table_attr,
                             GICV3_ITS_TABLE_PAGE_SIZE_4K,
                             1 /* num pages */);
    enableITS(gic_its);

    if (getITSPTA(gic_its)) // if PTA = 1
    {
        printf("GIC[%d] has PTA 1, which is not allowed for Multichip operation\n", gic_index);
        return 1;
    }

    initMultiChipITSTable(gic_index, gic_its, gic_its_int, rd);

    return 0;
}

// All the tables for each GIC are initialized from one core.
uint32_t initMultiChipITSs(struct GICv3_its_ctlr_if** mc_gic_its, struct GICv3_its_int_if** mc_gic_its_int, uint32_t* rd)
{
    for (unsigned num = 0; num < NUM_GICS ; ++num)
    {
        mc_gic_its[num]     = (struct GICv3_its_ctlr_if*)ITS_BASE_ADDR[num];
        mc_gic_its_int[num] = (struct GICv3_its_int_if*)(ITS_BASE_ADDR[num] + 0x010000);

        if (initMultiChipITS(num, mc_gic_its[num], mc_gic_its_int[num], rd))
            return 1;
    }
    return 0;
}

