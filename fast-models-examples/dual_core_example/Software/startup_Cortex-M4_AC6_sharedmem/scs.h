/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

#ifndef SCS_H_
#define SCS_H_

extern void SCS_init(void);

/* Masks for MPU Memory Region Sizes */
#define REGION_32B      0x08
#define REGION_64B      0x0A
#define REGION_128B     0x0C
#define REGION_256B     0x0E
#define REGION_512B     0x10
#define REGION_1K       0x12
#define REGION_2K       0x14
#define REGION_4K       0x16
#define REGION_8K       0x18
#define REGION_16K      0x1A
#define REGION_32K      0x1C
#define REGION_64K      0x1E
#define REGION_128K     0x20
#define REGION_256K     0x22
#define REGION_512K     0x24
#define REGION_1M       0x26
#define REGION_2M       0x28
#define REGION_4M       0x2A
#define REGION_8M       0x2C
#define REGION_16M      0x2E
#define REGION_32M      0x30
#define REGION_64M      0x32
#define REGION_128M     0x34
#define REGION_256M     0x36
#define REGION_512M     0x38
#define REGION_1G       0x3A
#define REGION_2G       0x3C
#define REGION_4G       0x3E

/* General MPU Masks */
#define REGION_ENABLED  0x1
#define REGION_VALID    0x10

#define SHAREABLE       0x40000
#define CACHEABLE       0x20000
#define BUFFERABLE      0x10000

/* Region Permissions */

#define NOT_EXEC        0x10000000 /* All Instruction fetches abort */

#define NO_ACCESS       0x00000000 /* Privileged No Access, Unprivileged No Access */
#define P_NA_U_NA       0x00000000 /* Privileged No Access, Unprivileged No Access */
#define P_RW_U_NA       0x01000000 /* Privileged Read Write, Unprivileged No Access */
#define P_RW_U_RO       0x02000000 /* Privileged Read Write, Unprivileged Read Only */
#define P_RW_U_RW       0x03000000 /* Privileged Read Write, Unprivileged Read Write */
#define FULL_ACCESS     0x03000000 /* Privileged Read Write, Unprivileged Read Write */
#define P_RO_U_NA       0x05000000 /* Privileged Read Only, Unprivileged No Access */
#define P_RO_U_RO       0x06000000 /* Privileged Read Only, Unprivileged Read Only */
#define RO              0x07000000 /* Privileged Read Only, Unprivileged Read Only */

/*
 * System Control Space (SCS) Register Struct
 * Structure containing all the SCS registers with appropriate padding
 */
typedef volatile struct {
    int Res00; // Master Control Register, Reserved
    int ICTR;  // Interrupt Controller Type Register
    int ACTLR; // Auxiliary Control Register
    int Res0c; // Reserved

    struct {
        int Ctrl;
        int Reload;
        int Value;
        int Calibration;
    } SysTick;

    int zReserved020_0fc[(0x100-0x20)/4];

    /* Offset 0x0100 */
    struct {
        int Enable[32];
        int Disable[32];
        int Set[32];
        int Clear[32];
        int Active[64];
        int Priority[64];
    } NVIC;

    int zReserved0x500_0xcfc[(0xd00-0x500)/4];

    /* Offset 0x0d00 */
    int CPUID; // CPUID Base Register
    int ICSR;  // Interrupt Control and State Register
    int VTOR;  // Vector Table Offset Register
    int AIRCR; // Application Interrupt and Reset Control Register
    int SCR;   // System Control Register
    int CCR;   // Configuration and Control Register
    int SHPR[3];  // System Handler Priority Register x3

    int zReserved0xd24_0xd88[(0xd88-0xd24)/4];

    /* Offset 0x0d88 */
    int CPACR;
    int Pad;        

    /* Offset 0x0d90 */
    struct {
        int Type;
        int Ctrl;
        int RegionNumber;
        int RegionBaseAddr;
        int RegionAttrSize;
    } MPU;

} SCS_t;


extern SCS_t SCS;

#endif /* SCS_H_*/
