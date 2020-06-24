/*
** Copyright (c) 2006-2017 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

#ifndef SCS_H_
#define SCS_H_


/*
 * System Control Space (SCS) Register Struct
 * Structure containing all the SCS registers with appropriate padding
 */
typedef volatile struct {
    int Res00; // Master Control Register, Reserved
    int ICTR;  // Interrupt Controller Type Register

    int zReserved008_00c[2];

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
        int Unused[64];
        int Priority[64];
    } NVIC;

    int zReserved0x500_0xcfc[(0xd00-0x500)/4];

    /* Offset 0x0d00 */
    int CPUID; // CPUID Base Register
    int ICSR;  // Interrupt Control and State Register
    int VTOR;  // Vector Table Offset Register
    int AIRCR; // Application Interrupt and Reset Control Register

} SCS_t;


extern SCS_t SCS;

#endif /* SCS_H_*/
