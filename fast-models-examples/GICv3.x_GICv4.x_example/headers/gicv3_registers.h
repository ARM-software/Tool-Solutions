// ----------------------------------------------------------
// GICv3 Memory mapped registers
// Header
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


#ifndef __gicv3_regs_h
#define __gicv3_regs_h

#include <stdint.h>

struct GICv3_dist_if
{
        volatile uint32_t GICD_CTLR;              // +0x0000 - RW - Distributor Control Register
  const volatile uint32_t GICD_TYPER;             // +0x0004 - RO - Interrupt Controller Type Register
  const volatile uint32_t GICD_IIDR;              // +0x0008 - RO - Distributor Implementer Identification Register

  const volatile uint32_t padding0;               // +0x000C - RESERVED

        volatile uint32_t GICD_STATUSR;           // +0x0010 - RW - Status register

  const volatile uint32_t padding1[3];            // +0x0014 - RESERVED

        volatile uint32_t IMP_DEF[8];             // +0x0020 - RW - Implementation defined registers

        volatile uint32_t GICD_SETSPI_NSR;        // +0x0040 - WO - Non-secure Set SPI Pending (Used when SPI is signalled using MSI)
  const volatile uint32_t padding2;               // +0x0044 - RESERVED
        volatile uint32_t GICD_CLRSPI_NSR;        // +0x0048 - WO - Non-secure Clear SPI Pending (Used when SPI is signalled using MSI)
  const volatile uint32_t padding3;               // +0x004C - RESERVED
        volatile uint32_t GICD_SETSPI_SR;         // +0x0050 - WO - Secure Set SPI Pending (Used when SPI is signalled using MSI)
  const volatile uint32_t padding4;               // +0x0054 - RESERVED
        volatile uint32_t GICD_CLRSPI_SR;         // +0x0058 - WO - Secure Clear SPI Pending (Used when SPI is signalled using MSI)

  const volatile uint32_t padding5[3];            // +0x005C - RESERVED

        volatile uint32_t GICD_SEIR;              // +0x0068 - WO - System Error Interrupt Register (Note: This was recently removed from the spec)

  const volatile uint32_t padding6[5];            // +0x006C - RESERVED

        volatile uint32_t GICD_IGROUPR[32];       // +0x0080 - RW - Interrupt Group Registers (Note: In GICv3, need to look at IGROUPR and IGRPMODR)

        volatile uint32_t GICD_ISENABLER[32];     // +0x0100 - RW - Interrupt Set-Enable Registers
        volatile uint32_t GICD_ICENABLER[32];     // +0x0180 - RW - Interrupt Clear-Enable Registers
        volatile uint32_t GICD_ISPENDR[32];       // +0x0200 - RW - Interrupt Set-Pending Registers
        volatile uint32_t GICD_ICPENDR[32];       // +0x0280 - RW - Interrupt Clear-Pending Registers
        volatile uint32_t GICD_ISACTIVER[32];     // +0x0300 - RW - Interrupt Set-Active Register
        volatile uint32_t GICD_ICACTIVER[32];     // +0x0380 - RW - Interrupt Clear-Active Register

        volatile uint8_t  GICD_IPRIORITYR[1024];  // +0x0400 - RW - Interrupt Priority Registers
        volatile uint32_t GICD_ITARGETSR[256];    // +0x0800 - RW - Interrupt Processor Targets Registers
        volatile uint32_t GICD_ICFGR[64];         // +0x0C00 - RW - Interrupt Configuration Registers
        volatile uint32_t GICD_GRPMODR[32];       // +0x0D00 - RW - Interrupt Group Modifier (Note: In GICv3, need to look at IGROUPR and IGRPMODR)
  const volatile uint32_t padding7[32];           // +0x0D80 - RESERVED
        volatile uint32_t GICD_NSACR[64];         // +0x0E00 - RW - Non-secure Access Control Register

        volatile uint32_t GICD_SGIR;              // +0x0F00 - WO - Software Generated Interrupt Register

  const volatile uint32_t padding8[3];            // +0x0F04 - RESERVED

        volatile uint32_t GICD_CPENDSGIR[4];      // +0x0F10 - RW - Clear pending for SGIs
        volatile uint32_t GICD_SPENDSGIR[4];      // +0x0F20 - RW - Set pending for SGIs

  const volatile uint32_t padding9[52];           // +0x0F30 - RESERVED
  
        // GICv3.1 extended SPI range
        volatile uint32_t GICD_IGROUPRE[128];     // +0x1000 - RW - Interrupt Group Registers (GICv3.1)
        volatile uint32_t GICD_ISENABLERE[128];   // +0x1200 - RW - Interrupt Set-Enable Registers (GICv3.1)
        volatile uint32_t GICD_ICENABLERE[128];   // +0x1400 - RW - Interrupt Clear-Enable Registers (GICv3.1)
        volatile uint32_t GICD_ISPENDRE[128];     // +0x1600 - RW - Interrupt Set-Pending Registers (GICv3.1)
        volatile uint32_t GICD_ICPENDRE[128];     // +0x1800 - RW - Interrupt Clear-Pending Registers (GICv3.1)
        volatile uint32_t GICD_ISACTIVERE[128];   // +0x1A00 - RW - Interrupt Set-Active Register (GICv3.1)
        volatile uint32_t GICD_ICACTIVERE[128];   // +0x1C00 - RW - Interrupt Clear-Active Register (GICv3.1)

  const volatile uint32_t padding10[128];         // +0x1E00 - RESERVED

        volatile uint8_t  GICD_IPRIORITYRE[4096]; // +0x2000 - RW - Interrupt Priority Registers (GICv3.1)

        volatile uint32_t GICD_ICFGRE[256];       // +0x3000 - RW - Interrupt Configuration Registers (GICv3.1)
        volatile uint32_t GICD_IGRPMODRE[128];    // +0x3400 - RW - Interrupt Group Modifier (GICv3.1)
        volatile uint32_t GICD_NSACRE[256];       // +0x3600 - RW - Non-secure Access Control Register (GICv3.1)

  const volatile uint32_t padding11[2432];        // +0x3A00 - RESERVED

        // GICv3.0
        volatile uint64_t GICD_ROUTER[1024];      // +0x6000 - RW - Controls SPI routing when ARE=1

        // GICv3.1
        volatile uint64_t GICD_ROUTERE[1024];     // +0x8000 - RW - Controls SPI routing when ARE=1 (GICv3.1)
};

struct GICv3_rdist_lpis_if
{
        volatile uint32_t GICR_CTLR;             // +0x0000 - RW - Redistributor Control Register
  const volatile uint32_t GICR_IIDR;             // +0x0004 - RO - Redistributor Implementer Identification Register
  const volatile uint32_t GICR_TYPER[2];         // +0x0008 - RO - Redistributor Type Register
        volatile uint32_t GICR_STATUSR;          // +0x0010 - RW - Redistributor Status register
        volatile uint32_t GICR_WAKER;            // +0x0014 - RW - Wake Request Registers
  const volatile uint32_t GICR_MPAMIDR;          // +0x0018 - RO - Reports maximum PARTID and PMG (GICv3.1)
        volatile uint32_t GICR_PARTID;           // +0x001C - RW - Set PARTID and PMG used for Redistributor memory accesses (GICv3.1)
  const volatile uint32_t padding1[8];           // +0x0020 - RESERVED
        volatile uint64_t GICR_SETLPIR;          // +0x0040 - WO - Set LPI pending (Note: IMP DEF if ITS present)
        volatile uint64_t GICR_CLRLPIR;          // +0x0048 - WO - Set LPI pending (Note: IMP DEF if ITS present)
  const volatile uint32_t padding2[6];           // +0x0058 - RESERVED
        volatile uint32_t GICR_SEIR;             // +0x0068 - WO - (Note: This was removed from the spec)
  const volatile uint32_t padding3;              // +0x006C - RESERVED
        volatile uint64_t GICR_PROPBASER;        // +0x0070 - RW - Sets location of the LPI configuration table
        volatile uint64_t GICR_PENDBASER;        // +0x0078 - RW - Sets location of the LPI pending table
  const volatile uint32_t padding4[8];           // +0x0080 - RESERVED
        volatile uint64_t GICR_INVLPIR;          // +0x00A0 - WO - Invalidates cached LPI config (Note: In GICv3.x: IMP DEF if ITS present)
  const volatile uint32_t padding5[2];           // +0x00A8 - RESERVED
        volatile uint64_t GICR_INVALLR;          // +0x00B0 - WO - Invalidates cached LPI config (Note: In GICv3.x: IMP DEF if ITS present)
  const volatile uint32_t padding6[2];           // +0x00B8 - RESERVED
        volatile uint64_t GICR_SYNCR;            // +0x00C0 - WO - Redistributor Sync
  const volatile uint32_t padding7[2];           // +0x00C8 - RESERVED
  const volatile uint32_t padding8[12];          // +0x00D0 - RESERVED
        volatile uint64_t GICR_MOVLPIR;          // +0x0100 - WO - IMP DEF
  const volatile uint32_t padding9[2];           // +0x0108 - RESERVED
        volatile uint64_t GICR_MOVALLR;          // +0x0110 - WO - IMP DEF
  const volatile uint32_t padding10[2];          // +0x0118 - RESERVED
};

struct GICv3_rdist_sgis_if
{
  const volatile uint32_t padding1[32];          // +0x0000 - RESERVED
        volatile uint32_t GICR_IGROUPR[3];       // +0x0080 - RW - Interrupt Group Registers (Security Registers in GICv1)
  const volatile uint32_t padding2[29];          // +0x008C - RESERVED
        volatile uint32_t GICR_ISENABLER[3];     // +0x0100 - RW - Interrupt Set-Enable Registers
  const volatile uint32_t padding3[29];          // +0x010C - RESERVED
        volatile uint32_t GICR_ICENABLER[3];     // +0x0180 - RW - Interrupt Clear-Enable Registers
  const volatile uint32_t padding4[29];          // +0x018C - RESERVED
        volatile uint32_t GICR_ISPENDR[3];       // +0x0200 - RW - Interrupt Set-Pending Registers
  const volatile uint32_t padding5[29];          // +0x020C - RESERVED
        volatile uint32_t GICR_ICPENDR[3];       // +0x0280 - RW - Interrupt Clear-Pending Registers
  const volatile uint32_t padding6[29];          // +0x028C - RESERVED
        volatile uint32_t GICR_ISACTIVER[3];     // +0x0300 - RW - Interrupt Set-Active Register
  const volatile uint32_t padding7[29];          // +0x030C - RESERVED
        volatile uint32_t GICR_ICACTIVER[3];     // +0x0380 - RW - Interrupt Clear-Active Register
  const volatile uint32_t padding8[29];          // +0x018C - RESERVED
        volatile uint8_t  GICR_IPRIORITYR[96];   // +0x0400 - RW - Interrupt Priority Registers
  const volatile uint32_t padding9[488];         // +0x0460 - RESERVED
        volatile uint32_t GICR_ICFGR[6];         // +0x0C00 - RW - Interrupt Configuration Registers
  const volatile uint32_t padding10[58];	 // +0x0C18 - RESERVED
        volatile uint32_t GICR_IGRPMODR[3];      // +0x0D00 - RW - Interrupt Group Modifier Register
  const volatile uint32_t padding11[61];	 // +0x0D0C - RESERVED
        volatile uint32_t GICR_NSACR;            // +0x0E00 - RW - Non-secure Access Control Register

};

struct GICv3_rdist_vlpis_if
{
  const volatile uint32_t padding1[28];          // +0x0000 - RESERVED
        volatile uint64_t GICR_VPROPBASER;       // +0x0070 - RW - Sets location of the LPI vPE Configuration table
        volatile uint64_t GICR_VPENDBASER;       // +0x0078 - RW - Sets location of the LPI Pending table
};

struct GICv3_rdist_res_if
{
  const volatile uint32_t padding1[32];          // +0x0000 - RESERVED
};

struct GICv3_rdist_if
{
  struct GICv3_rdist_lpis_if   lpis  __attribute__((aligned (0x10000)));
  struct GICv3_rdist_sgis_if   sgis  __attribute__((aligned (0x10000)));

  #ifdef GICV4
  struct GICv3_rdist_vlpis_if  vlpis __attribute__((aligned (0x10000)));
  struct GICv3_rdist_res_if    res   __attribute__((aligned (0x10000)));
  #endif
};


// +0 from ITS_BASE
struct GICv3_its_ctlr_if
{
        volatile uint32_t GITS_CTLR;             // +0x0000 - RW - ITS Control Register
  const volatile uint32_t GITS_IIDR;             // +0x0004 - RO - Implementer Identification Register
  const volatile uint64_t GITS_TYPER;            // +0x0008 - RO - ITS Type register
  const volatile uint32_t GITS_MPAMIDR;          // +0x0010 - RO - Reports maxmimum PARTID and PMG (GICv3.1)
        volatile uint32_t GITS_PARTIDR;          // +0x0004 - RW - Sets the PARTID and PMG used for ITS memory accesses (GICv3.1)
  const volatile uint32_t GITS_MPIDR;            // +0x0018 - RO - ITS affinity, used for shared vPE table
  const volatile uint32_t padding5;              // +0x001C - RESERVED
        volatile uint32_t GITS_IMPDEF[8];        // +0x0020 - RW - IMP DEF registers
  const volatile uint32_t padding2[16];          // +0x0040 - RESERVED
        volatile uint64_t GITS_CBASER;           // +0x0080 - RW - Sets base address of ITS command queue
        volatile uint64_t GITS_CWRITER;          // +0x0088 - RW - Points to next enrty to add command
        volatile uint64_t GITS_CREADR;           // +0x0090 - RW - Points to command being processed
  const volatile uint32_t padding3[2];           // +0x0098 - RESERVED
  const volatile uint32_t padding4[24];          // +0x00A0 - RESERVED
        volatile uint64_t GITS_BASER[8];         // +0x0100 - RW - Sets base address of Device and Collection tables
};

// +0x010000 from ITS_BASE
struct GICv3_its_int_if
{
  const volatile uint32_t padding1[16];          // +0x0000 - RESERVED
        volatile uint32_t GITS_TRANSLATER;       // +0x0040 - RW - Written by peripherals to generate LPI
};

// +0x020000 from ITS_BASE
struct GICv3_its_sgi_if
{
  const volatile uint32_t padding1[8];           // +0x0000 - RESERVED
        volatile uint64_t GITS_SGIR;             // +0x0020 - RW - Written by peripherals to generate vSGI (GICv4.1)
};

#endif

// ----------------------------------------------------------
// End of gicv3_regs.h
// ----------------------------------------------------------
