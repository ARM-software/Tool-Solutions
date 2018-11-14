/*
** Copyright (c) 2018 Arm Limited. All rights reserved.
*/

#include <stdio.h>

extern void init_serial(void);

int main(void)
{
    #ifdef UART
        init_serial();
    #endif    
    
    printf("\nHello World!\n");

    printf("\npress Ctrl-C to exit\n");

    return 0;
}
