#include <stdio.h>
#include <stdint.h>
#include "uart_stdout.h"

#define SERIAL_BASE_ADDRESS        0xA8000000
#define SERIAL_DATA            * ((volatile unsigned   *) SERIAL_BASE_ADDRESS   )

int stdout_putchar(char txchar)
{
  SERIAL_DATA = txchar;
  if (txchar == '\n')
    {
      txchar = '\r';
      stdout_putchar(txchar);
    }
}

int stderr_putchar(char txchar)
{
  return stdout_putchar(txchar);
}


