/*
** Copyright (c) 2020 Arm Limited. All rights reserved.
*/
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#define ICIALLU 0xE000EF50
#define CCR     0xE000ED14    /* configuration and control reg */

#define LENGTH  64 

uint32_t read_reg(uint32_t address)
{
    return *((volatile uint32_t *)address);
}

void write_reg(uint32_t address, uint32_t data)
{
    *((volatile uint32_t *) address) = data;
}

void cache_init()
{
    // Invalidate caches 
    write_reg(ICIALLU, 0);

    // Enable both I & D caches 
    write_reg(CCR, (read_reg(CCR) | 0x30000));
}

__attribute__((noinline)) void init_arrays(short *a, short *b, int length)
{
    int i;

    for(i = 0; i < length; i++)
    {
        a[i] = i;
        b[i] = i;
    }
}

/* 
   Example of a multiply-accumulate (MLA) function
   that can be auto-vectorized by Arm Compiler 6
   The compiler can also generate low-overload loop
   instructions for the loop within this function.
 */
__attribute__((noinline)) int mla(short *a, short *b, int length)
{
    int i;
    int sum = 0;

    for(i = 0; i < length; i++)
    {
        sum += a[i] * b[i];
    }

    return sum;
}

int main()
{
    short a[LENGTH], b[LENGTH];

    (void) cache_init();

    printf("\nHello from Cortex-M55!\n\n");

    // Test new instructions
    __asm volatile (
            "vmov.i32   q0, #0x0            \n"
            "vabs.f32   q0, q0              \n"
            :
            :
            : "q0"
       );

    (void) init_arrays(a, b, LENGTH); 
    printf("Sum is: %d\n", mla(a, b, LENGTH));

    return 0;
}
