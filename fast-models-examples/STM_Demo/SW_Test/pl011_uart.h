// ----------------------------------------------------------
// Copyright ARM Ltd 2005-2011. All rights reserved.
//
// Code for PL011 UART - retargets fputc()
// ----------------------------------------------------------

#ifndef __uart_h
#define __uart_h

void uartInit(void* addr);      // Must be called before printf() or uartSendString() is called!
void uartSendString(const char*);
int  uart_fputc(int c, FILE *f);

#endif

// ----------------------------------------------------------
// End of pl011_uart.h
// ----------------------------------------------------------
