/*
 * AMBA-PV: types.h - Basic types definition.
 *
 * Copyright 2007-2010 ARM Limited.
 * All rights reserved.
 */

#ifndef TYPES__H
#define TYPES__H

/* Includes */
#include <amba_pv.h>

/* Datatypes */

/*
 * Bus data type.
 */
typedef unsigned int data_t;

/*
 * Bus width in bits.
 */
static const unsigned int BUSWIDTH = sizeof(data_t) * 8;

/*
 * Signal state type.
 */
typedef bool signal_t;

/*
 * Maximum burst length.
 */
static const unsigned int BURSTLENGTH = 16U;

#endif  /* defined(TYPES__H) */
