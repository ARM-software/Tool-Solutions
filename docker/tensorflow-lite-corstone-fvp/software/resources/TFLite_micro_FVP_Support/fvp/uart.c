/*
** Copyright (c) 2018 Arm Limited (or its affiliates). All rights reserved.
** Use, modification and redistribution of this file is subject to your possession of a
** valid End User License Agreement for the Arm Product of which these examples are part of 
** and your compliance with all applicable terms and conditions of such licence agreement.
*/

/* Simple polled UART driver for Cortex-M MPS2 FVP model */

// Ensure uart_init() is called before any other functions in this file.

typedef struct
{
  volatile unsigned int DATA;
  volatile unsigned int STATE;
  volatile unsigned int CTRL;
  volatile unsigned int INTERRUPT;
  volatile unsigned int BAUDDIV;
} UART_struct;

// UART at 0x50200000 in SSE-200 (see MPS2+ documentation)
#define UART ((UART_struct *) 0x49303000UL )

void uart_init(void)
{
  UART->BAUDDIV = 16;
  UART->CTRL    = 0x41; // High speed test mode, TX only
}

void uart_putc_polled(char c)
{
  while ((UART->STATE & 1)); // Wait if Transmit Holding register is full
  UART->DATA = c;
}

char uart_getchar_polled(void)
{
  while ((UART->STATE & 2)==0); // Wait if Receive Holding register is empty
  return (UART->DATA);
}
