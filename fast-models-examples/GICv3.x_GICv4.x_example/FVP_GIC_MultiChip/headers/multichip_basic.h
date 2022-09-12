#ifndef MULTICHIP_BASIC_H
#define MULTICHIP_BASIC_H

#define DSB asm("dsb sy");

#define NUM_GICS 8 // Determined by the cluster connections. FVP_Base_AEMv8A-AEMv8A has only 8 CPUs, each connected to a separate GIC.
                   // Although MultiGIC has 16 GICs, not all of them are connected and used.

static const uint64_t DIST0_BASE_ADDR = 0x2F000000;
static const uint64_t DIST_BASE_ADDR[MAX_NUM_CHIPS] = {DIST0_BASE_ADDR, DIST0_BASE_ADDR + (GIC_OFFSET), DIST0_BASE_ADDR + (2 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (3 * GIC_OFFSET), DIST0_BASE_ADDR + (4 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (5 * GIC_OFFSET), DIST0_BASE_ADDR + (6 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (7 * GIC_OFFSET), DIST0_BASE_ADDR + (8 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (9 * GIC_OFFSET), DIST0_BASE_ADDR + (10 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (11 * GIC_OFFSET), DIST0_BASE_ADDR + (12 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (13 * GIC_OFFSET), DIST0_BASE_ADDR + (14 * GIC_OFFSET),
                                                DIST0_BASE_ADDR + (15 * GIC_OFFSET)};

static const uint64_t ITS0_BASE_ADDR = 0x2F040000;
static const uint64_t ITS_BASE_ADDR[MAX_NUM_CHIPS] = {ITS0_BASE_ADDR, ITS0_BASE_ADDR + (GIC_OFFSET), ITS0_BASE_ADDR + (2 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (3 * GIC_OFFSET), ITS0_BASE_ADDR + (4 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (5 * GIC_OFFSET), ITS0_BASE_ADDR + (6 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (7 * GIC_OFFSET), ITS0_BASE_ADDR + (8 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (9 * GIC_OFFSET), ITS0_BASE_ADDR + (10 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (11 * GIC_OFFSET), ITS0_BASE_ADDR + (12 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (13 * GIC_OFFSET), ITS0_BASE_ADDR + (14 * GIC_OFFSET),
                                               ITS0_BASE_ADDR + (15 * GIC_OFFSET)};

static const uint64_t RD0_BASE_ADDR = 0x2F080000;
static const uint64_t RD_BASE_ADDR[MAX_NUM_CHIPS] = {RD0_BASE_ADDR, RD0_BASE_ADDR + (GIC_OFFSET), RD0_BASE_ADDR + (2 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (3 * GIC_OFFSET), RD0_BASE_ADDR + (4 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (5 * GIC_OFFSET), RD0_BASE_ADDR + (6 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (7 * GIC_OFFSET), RD0_BASE_ADDR + (8 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (9 * GIC_OFFSET), RD0_BASE_ADDR + (10 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (11 * GIC_OFFSET), RD0_BASE_ADDR + (12 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (13 * GIC_OFFSET), RD0_BASE_ADDR + (14 * GIC_OFFSET),
                                              RD0_BASE_ADDR + (15 * GIC_OFFSET)};

// Below memory is based at FVP Base platform memory map.
static const uint32_t CONFIG_TABLE_BASE                = 0x80020000;
static const uint32_t PENDING_TABLE_BASE               = 0x80030000;
static const uint32_t COMMAND_QUEUE_TABLE_BASE         = 0x80040000;
static const uint32_t DEVICE_TABLE_BASE                = 0x80050000;
static const uint32_t COLLECTION_TABLE_BASE            = 0x80060000;
static const uint32_t VPE_CONFIG_TABLE_BASE            = 0x80070000;
static const uint32_t VCONFIG_TABLE_BASE               = 0x80080000;
static const uint32_t VPENDING_TABLE_BASE              = 0x80090000;
static const uint32_t INTERRUPT_TRANSLATION_TABLE_BASE = 0x800A0000;

static const uint32_t ITS_SIZE = 0x000B0000;

#define ITS_MEMORY_MAP(TBL) static const uint32_t TBL[MAX_NUM_CHIPS] = {\
                                TBL##_BASE + ( 0 * ITS_SIZE), TBL##_BASE + ( 1 * ITS_SIZE), \
                                TBL##_BASE + ( 2 * ITS_SIZE), TBL##_BASE + ( 3 * ITS_SIZE), \
                                TBL##_BASE + ( 4 * ITS_SIZE), TBL##_BASE + ( 5 * ITS_SIZE), \
                                TBL##_BASE + ( 6 * ITS_SIZE), TBL##_BASE + ( 7 * ITS_SIZE), \
                                TBL##_BASE + ( 8 * ITS_SIZE), TBL##_BASE + ( 9 * ITS_SIZE), \
                                TBL##_BASE + (10 * ITS_SIZE), TBL##_BASE + (11 * ITS_SIZE), \
                                TBL##_BASE + (12 * ITS_SIZE), TBL##_BASE + (13 * ITS_SIZE), \
                                TBL##_BASE + (14 * ITS_SIZE), TBL##_BASE + (15 * ITS_SIZE)};

ITS_MEMORY_MAP(CONFIG_TABLE)
ITS_MEMORY_MAP(PENDING_TABLE)
ITS_MEMORY_MAP(COMMAND_QUEUE_TABLE)
ITS_MEMORY_MAP(DEVICE_TABLE)
ITS_MEMORY_MAP(COLLECTION_TABLE)
ITS_MEMORY_MAP(VPE_CONFIG_TABLE)
ITS_MEMORY_MAP(VCONFIG_TABLE)
ITS_MEMORY_MAP(VPENDING_TABLE)
ITS_MEMORY_MAP(INTERRUPT_TRANSLATION_TABLE)

static const uint32_t CORE_FIELD_WIDTH = 2; // Default maximum number of CPUs is 4

struct GICv3AddressWrapper;

bool cmpMultiRegs(unsigned master_id, struct GICv3AddressWrapper **gic);
uint32_t initMultiChip(unsigned master_id, struct GICv3AddressWrapper **gic, uint32_t *rd);
uint32_t initGIC(unsigned gicID, struct GICv3AddressWrapper **gic, uint32_t *rd);

void activateInterrupts(uint64_t distBase, uint64_t RdistBase, unsigned gicID, struct GICv3AddressWrapper **gic, uint32_t* rd);
void fiqHandler(void);

uint32_t initMultiChipLPITables(struct GICv3AddressWrapper **gic);
uint32_t initMultiChipITSs(struct GICv3_its_ctlr_if** mc_gic_its, struct GICv3_its_int_if** mc_gic_its_int, uint32_t* rd);

uint32_t initMultiChipITS(unsigned index, struct GICv3_its_ctlr_if* gic_its, struct GICv3_its_int_if* gic_its_int, uint32_t* rd);
uint32_t initMultiChipITSTable(unsigned index, struct GICv3_its_ctlr_if* gic_its, struct GICv3_its_int_if* gic_its_int, uint32_t* rd);

void setITSTableAddrWithCheck(struct GICv3_its_ctlr_if* gic_its, unsigned gits_baser_index, uint8_t table_type,
                              uint64_t addr, uint64_t attributes, uint32_t page_size, uint32_t num_pages);

#endif // MULTICHIP_BASIC_H
