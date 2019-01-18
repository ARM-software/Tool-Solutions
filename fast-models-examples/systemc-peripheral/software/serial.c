/*
** Copyright (c) 2018 Arm Limited. All rights reserved.
*/

#include "uart.h"
#include <stdio.h>



// PL011 UART Code
// ================
void init_serial(void)
{
    // Disable the serial port while setting the baud rate and word length
    UART0_CR = 0;

    // Set the correct baud rate and word length  
    UART0_LCRL = LCRL_Baud_460800;                         
    UART0_LCRM = LCRM_Baud_460800;                        
    UART0_LCRH = LCRH_Word_Length_8;    

    // Now enable the serial port                                   
    UART0_CR   = CR_UART_Enable | CR_TX_Int_Enable | CR_RX_Int_Enable;        // Enable UART0 with no interrupts
}

void sendchar(char ch)
{
    while (UART0_FR & FR_TX_Fifo_Full)
        ;
    UART0_DR = ch;                     
    if (ch == '\n')                    
    {
        ch = '\r';                     
        sendchar(ch);
    }
}



// ReTargeting Code
// ================
#ifdef UART

asm("  .global __use_no_semihosting\n");

struct __FILE {int handle;};
FILE __stdout;
FILE __stdin;
FILE __stderr;
    
int fputc(int ch, FILE *f)
{
    char tempch = ch;
    (void) sendchar(tempch);
    return ch;
}

void _ttywrch(int ch)
{
    char tempch = ch;
    (void) sendchar(tempch);
}

void _sys_exit(int return_code)
{
    while(1);
}

#endif
 
