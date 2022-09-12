/*!
 * \file    SystemUtils.h
 * \brief   System utility functions.
 *
 *  Copyright 2018 ARM Limited. All rights reserved.
 */

#ifndef CPUID_H
#define CPUID_H

#include <stdint.h>
#include <stdbool.h>

/*
 * Parameters for data barriers
 */
#define OSHLD   1
#define OSHST   2
#define OSH     3
#define NSHLD   5
#define NSHST   6
#define NSH     7
#define ISHLD   9
#define ISHST  10
#define ISH    11
#define LD     13
#define ST     14
#define SY     15

/**********************************************************************/
/*
 * function prototypes
 */

/*
 * void InvalidateUDCaches(void)
 *   invalidates all Unified and Data Caches
 *
 * Inputs
 *   <none>
 *
 * Returns
 *   <nothing>
 *
 * Side Effects
 *   guarantees that all levels of cache will be invalidated before
 *   returning to caller
 */
extern void InvalidateUDCaches(void);

/*
 * unsigned long long EnableCachesEL1(void)
 *   enables I- and D- caches at EL1
 *
 * Inputs
 *   <none>
 *
 * Returns
 *   New value of SCTLR_EL1
 *
 * Side Effects
 *   context will be synchronised before returning to caller
 */
extern unsigned long long EnableCachesEL1(void);

/*
 * unsigned long long GetMIDR(void)
 *   returns the contents of MIDR_EL0
 *
 * Inputs
 *   <none>
 *
 * Returns
 *   MIDR_EL0
 */
extern unsigned long long GetMIDR(void);

/*
 * unsigned long long GetMPIDR(void)
 *   returns the contents of MPIDR_EL0
 *
 * Inputs
 *   <none>
 *
 * Returns
 *   MPIDR_EL0
 */
extern unsigned long long GetMPIDR(void);

/*
 * unsigned int GetCPUID(void)
 *   returns the Aff0 field of MPIDR_EL0
 *
 * Inputs
 *   <none>
 *
 * Returns
 *   MPIDR_EL0[7:0]
 */
extern unsigned int GetCPUID(void);

typedef void (*callback_t)(void);

extern void doWriteNSBit(bool nonsecure);

extern __attribute__((noreturn)) void toHandlerMode(callback_t fp);
extern __attribute__((noreturn)) void toThreadMode(callback_t fp);
extern __attribute__((noreturn)) void changeCurrentStack(callback_t fp, uint64_t* stack);

extern uint64_t* readSP(void);
#endif
