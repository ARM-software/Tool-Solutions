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

void init_uart();
void sendchar(unsigned char my_ch);
void ttywrch (int ch);
  

#if __cplusplus
}
#endif

  
#define UARTBASE 0x40004000    
#define BAUDRATE 0x9600     //        int BaudRate = BAUDRATE;     // Other common bauds: 38400
#define SYSTEM_CORE_CLK 25000000  // CLK of board, important for APB_UART. 25MHz is the frequency of the MPS2 FPGA board


//____________________________________________________________________________________
//_________________________________ APB_UART _________________________________________
//____________________________________________________________________________________

    #define APB_DATA      *((volatile unsigned *)(UARTBASE + 0x00)) 
    //  |-- 8 wide --|      RW      Reset=0x--
        // [7:0]   Data value
            // Read => Recieved data
            // Write=> Transmit data
        
    #define APB_STATE     *((volatile unsigned *)(UARTBASE + 0x04))
    //  |-- 4 wide --|      RW      Reset=0x0
        #define STATE_RX_OVERRUN (1ul <<  3)             // RX buffer overrun. Write 1 to clear. 
        #define STATE_TX_OVERRUN (1ul <<  2)             // TX buffer overrun. Write 1 to clear. 
        #define STATE_RX_FULL    (1ul <<  1)             // RX buffer full, read only
        #define STATE_TX_FULL    (1ul <<  0)             // TX buffer full, read only

    #define APB_CTRL      *((volatile unsigned *)(UARTBASE + 0x08))
    //  |-- 7 wide --|      RW      Reset=0x00
        #define CTRL_TX_HS_TEST_MODE  (1ul <<  6)        // High-speed test mode for TX only.
        #define CTRL_RX_OV_INT_ENABLE (1ul <<  5)        // RX overrun interrupt enable.
        #define CTRL_TX_OV_INT_ENABLE (1ul <<  4)        // TX overrun interrupt enable.
        #define CTRL_RX_INT_ENABLE    (1ul <<  3)        // RX interrupt enable.
        #define CTRL_TX_INT_ENABLE    (1ul <<  2)        // TX interrupt enable.
        #define CTRL_RX_ENABLE        (1ul <<  1)        // RX enable.
        #define CTRL_TX_ENABLE        (1ul <<  0)        // TX enable.

    #define APB_INT       *((volatile unsigned *)(UARTBASE + 0x0C))
    //  |-- 4 wide --|      RW      Reset=0x0
        #define INT_RX_OV_INT (1ul <<  4)                 // RX overrun interrupt. Write 1 to clear.
        #define INT_TX_OV_INT (1ul <<  3)                 // TX overrun interrupt. Write 1 to clear.
        #define INT_RX_INT    (1ul <<  2)                 // RX interrupt. Write 1 to clear.
        #define INT_TX_INT    (1ul <<  1)                 // TX interrupt. Write 1 to clear.

    #define APB_BAUDDIV   *((volatile unsigned *)(UARTBASE + 0x10)) // Baud rate divider register. 20 bits wide
    //  |-- 20 wide --|     RW      Reset=0x00000
        // Minimum = 0x00010  (16)
        // Maximum = 0xFFFFF  (1048576) 
        // if CLK=12MHZ, and required baud rate is 9600, the register must be  12,000,000/9600 = 1250 = 0x4e2

#endif







