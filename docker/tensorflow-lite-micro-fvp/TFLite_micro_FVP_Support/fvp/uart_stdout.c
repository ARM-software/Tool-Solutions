/*
** Copyright (c) 2018 Arm Limited. All rights reserved.
*/

#include "uart_stdout.h"
#include <stdio.h>
#include <stdint.h>


void init_uart(void)
{
    
        APB_CTRL = 0;                                     // Disable the serial port while setting the baud rate and word length
        APB_BAUDDIV  = SYSTEM_CORE_CLK / BAUDRATE;        // Baud of 38400 at 25MHz
        APB_CTRL     = CTRL_TX_ENABLE | CTRL_RX_ENABLE;   // Enable UART with no interrupts
  
}


void sendchar(unsigned char ch)
{

        while (APB_STATE & STATE_TX_FULL);      // while the transmit flag indicates that there is more to send
        APB_DATA = ch;                         // Transmit next character

}




// ReTargeting Code
// ================
/*
** Importing __use_no_semihosting ensures that our image doesn't link
** with any C Library code that makes direct use of semihosting. 
*/
    /*
    ** Retargeted I/O
    ** ==============
    ** The following C library functions make use of semihosting
    ** to read or write characters to the debugger console: fputc(),
    ** fgetc(), and _ttywrch().  They must be retargeted to write to
    ** the Integrator AP UART.  __backspace() must also be retargeted
    ** with this layer to enable scanf().  See the Compiler and
    ** Libraries Guide.
    */
 
//    asm("  .global __use_no_semihosting\n");

/*    struct __FILE {int handle;};
    FILE __stdout;
    FILE __stdin;
    FILE __stderr; */
        
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



   



  
