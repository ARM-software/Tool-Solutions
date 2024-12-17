#include <stdio.h>
#include "pl011_uart.h"
#include "stm.h"

#define USE_STM


#ifdef USE_STM
struct STM *gSTM;
#   define  PLATFORM_STM_AXI_ADDRESS    0x28000000ULL
#   define  PLATFORM_STM_APB_ADDRESS    0x20100000ULL
#else
#   define  PLATFORM_UART_ADDRESS       0x40004000
#endif

int fputc(int c, FILE *f) {
  #ifdef USE_STM
      return stm_fputc(gSTM, c, f);
  #else
      return uart_fputc(c,f);
  #endif
}

int main (void) {
  #ifdef USE_STM
    /* Initialize the STM */
    struct STM stm = { 0 };
    gSTM = (struct STM *) &stm;

    stmInit(
                gSTM,
                (struct stmAPB *) PLATFORM_STM_APB_ADDRESS,
                (struct stmAXI *) PLATFORM_STM_AXI_ADDRESS
            );
    stmSendString(gSTM, 0, "Test STM String\n");
    // stmSendString(gSTM, 1, "Test STM String\n");
  #else
      uartInit((void*)(PLATFORM_UART_ADDRESS));
  #endif
  printf("hello world\n");
  return 0;
}
