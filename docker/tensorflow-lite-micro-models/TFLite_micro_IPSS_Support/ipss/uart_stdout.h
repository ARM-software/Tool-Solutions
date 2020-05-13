#ifndef _UART_STDOUT_H_
#define _UART_STDOUT_H_
#define TRUE 1
#define FALSE 0

#if __cplusplus
extern "C"
{
#endif

/* Functions for stdout during simulation */
/* The functions are implemented in uart_stdout.c */
  
int stdout_putchar(char my_ch);


#if __cplusplus
}
#endif

#endif
