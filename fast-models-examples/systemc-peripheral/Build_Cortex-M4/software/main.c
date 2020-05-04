/*
** Copyright (c) 2018 Arm Limited. All rights reserved.
*/

#include <stdio.h>

extern void init_serial(void);

int main(void)
{
    unsigned char *sim_exit = (unsigned char *) 0x1c090ffc;

    #ifdef UART
        init_serial();
    #endif    
    
    printf("\nHello World!\n");

    // Comment out this line to see the messages in the terminal 
    // and manually exit using Ctrl-C
    printf("\nWriting to peripheral to exit SystemC simulation\n");
    *sim_exit = 0xff;

    return 0;
}
