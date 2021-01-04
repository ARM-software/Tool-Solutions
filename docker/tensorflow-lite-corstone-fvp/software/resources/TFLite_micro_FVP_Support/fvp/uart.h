/******************************************************************************
**                                                                           **
**  Copyright (c) 2020 ARM Limited                                           **
**  All rights reserved                                                      **
**                                                                           **
******************************************************************************/

/* 
# Options:
#       APB_UART or Cortex-M FVP / MPS2 FPGA
#       PL_011 or FM
#       ITM
#       SEMIHOST
*/

#ifndef __UARTDEF
#define __UARTDEF
#include <stdio.h>

#if __cplusplus
extern "C"
{
#endif

void uart_init();
void uart_putc_polled(char my_ch);
  

#if __cplusplus
}
#endif
#endif

  


    

    








