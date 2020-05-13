//
// Copyright:
// ----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from ARM Limited.
//      (C) COPYRIGHT 2018-2019 ARM Limited, ALL RIGHTS RESERVED
// The entire notice above must be reproduced on all authorized copies and
// copies may only be made to the extent permitted by a licensing agreement
// from ARM Limited.
// ----------------------------------------------------------------------------
//

#include "cmsis.h"
#include <stdio.h>
#include "uart_stdout.h"

#define CCR_DL   (1 << 19)

using ExecFuncPtr = void (*)();

extern "C" void Image$$ARM_LIB_STACK$$ZI$$Base();
extern "C" void Image$$ARM_LIB_STACK$$ZI$$Limit();
extern "C" void Image$$ARM_LIB_HEAP$$ZI$$Base();
extern "C" void Image$$ARM_LIB_HEAP$$ZI$$Limit();
extern "C" __attribute__((noreturn)) void __main();
extern "C" __attribute__((section("BOOT"), noreturn, used)) void __start();

// Exception context
struct ExcContext
{
    uint32_t r0;
    uint32_t r1;
    uint32_t r2;
    uint32_t r3;
    uint32_t r12;
    uint32_t lr;
    uint32_t pc;
    uint32_t xPsr;
};

__attribute__((noreturn)) void Hang()
{
    while (true)
    {
        // Without the following line, armclang may optimize away the infinite loop
        // because it'd be without side effects and thus undefined behaviour.
        __ASM volatile("");
    }
}

__attribute__((interrupt("IRQ"), noreturn, used)) void HangIrq()
{
    while (true)
    {
        // Without the following line, armclang may optimize away the infinite loop
        // because it'd be without side effects and thus undefined behaviour.
        __ASM volatile("");
    }
}

extern "C" __attribute__((naked, used)) void __user_setup_stackheap()
{
    __ASM volatile("LDR  r0, =Image$$ARM_LIB_HEAP$$ZI$$Base");
    __ASM volatile("LDR  r1, =Image$$ARM_LIB_STACK$$ZI$$Limit");
    __ASM volatile("LDR  r2, =Image$$ARM_LIB_HEAP$$ZI$$Limit");
    __ASM volatile("LDR  r3, =Image$$ARM_LIB_STACK$$ZI$$Base");
    __ASM volatile("bx   lr");
}

extern "C" void InterruptHandler();

extern "C" const ExecFuncPtr g_InitVtor[] __attribute__((section("VECTOR_TABLE"), used)) = {
    &Image$$ARM_LIB_STACK$$ZI$$Limit,    // Initial SP
    &__start,                            // Initial PC, set to entry point
    &InterruptHandler,                   // NMIException
    &InterruptHandler,                   // HardFaultException
    &InterruptHandler,                   // MemManageException
    &InterruptHandler,                   // BusFaultException
    &InterruptHandler,                   // UsageFaultException
    0,                                   // Reserved
    0,                                   // Reserved
    0,                                   // Reserved
    0,                                   // Reserved
    &InterruptHandler,                   // SVCHandler
    &InterruptHandler,                   // DebugMonitor
    0,                                   // Reserved
    &InterruptHandler,                   // PendSVC
    &InterruptHandler,                   // SysTickHandler

    /* Configurable interrupts start here...*/
#if defined(FPGA)
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
#if !defined(CPU_M55)
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
#endif
#endif
    &InterruptHandler   // HactarIrq
};

#define STR(x) #x
#define RESET_REG(n) __ASM volatile("MOV " STR(r##n) ", #0" : : : STR(r##n))

extern "C" __attribute__((section("BOOT"), noreturn, used)) void __start()
{


#if (defined (__FPU_USED) && (__FPU_USED == 1U)) || \
    (defined (__MVE_USED) && (__MVE_USED == 1U))
    SCB->CPACR |= ((3U << 10U*2U) |           /* enable CP10 Full Access */
                   (3U << 11U*2U)  );
#endif

    // Initialise registers r0-r12 and LR(=r14)
    // They must have a valid value before being potentially pushed to stack by
    // C calling convention or by context saving in exception handling
    //
    RESET_REG(0);
    RESET_REG(1);
    RESET_REG(2);
    RESET_REG(3);
    RESET_REG(4);
    RESET_REG(5);
    RESET_REG(6);
    RESET_REG(7);
    RESET_REG(8);
    RESET_REG(9);
    RESET_REG(10);
    RESET_REG(11);
    RESET_REG(12);
    RESET_REG(14);

    // Update init vector table
#if defined(CPU_M0)
    ExecFuncPtr* vectorTable = reinterpret_cast<ExecFuncPtr*>(SCB->RESERVED0);
#else
    ExecFuncPtr* vectorTable = reinterpret_cast<ExecFuncPtr*>(SCB->VTOR);
#endif
    for (size_t i = 0; i < sizeof(g_InitVtor) / sizeof(g_InitVtor[0]); i++)
    {
        vectorTable[i] = g_InitVtor[i];
    }

#if defined(CPU_M7)
    // MPU
    Mpu::BootConfig();

    // Caches
    Cache::IEnable();
    Cache::DEnable();
#endif

#if !defined(CPU_M0)
    // Enable hard, bus, mem and usage fault detection in SHCSR, bits 16-18.
    // Enable stkof, bf, div_0_trp, unalign_trp and usersetm bits in CCR
    SCB->SHCSR =
        _VAL2FLD(SCB_SHCSR_USGFAULTENA, 1) | _VAL2FLD(SCB_SHCSR_BUSFAULTENA, 1) | _VAL2FLD(SCB_SHCSR_MEMFAULTENA, 1);

    SCB->CCR = _VAL2FLD(SCB_CCR_USERSETMPEND, 1) | _VAL2FLD(SCB_CCR_DIV_0_TRP, 1) |
               _VAL2FLD(SCB_CCR_BFHFNMIGN, 1)
#if defined(CPU_M33) || defined(CPU_M55)
               | _VAL2FLD(SCB_CCR_STKOFHFNMIGN, 1)
#endif
#ifdef UNALIGNED_SUPPORT_DISABLE
               | _VAL2FLD(SCB_CCR_UNALIGN_TRP, 1)
#endif
#endif
               ;
#if defined(CPU_M55)
     SCB->CCR |= CCR_DL;
#endif
    // Reset pipeline
    __DSB();
    __ISB();

    
    // Call into libcxx startup sequence
    __main();
}

namespace
{
void printString(const char* str)
{
    for (; *str; str++)
    {
        stdout_putchar(*str);
    }
}

// Print an integer without printf
#define printInt(x) printString(#x); printString(" : 0x"); _printInt(x)
void _printInt(int x)
{
    for (int i = 32-4; i >= 0; i-=4)
    {
        int a = (x >> i) & 0xf;
        if (a < 10) a = a + 0x30;
        else a = 0x61 + a - 0xa;

        stdout_putchar(a);
    }
    stdout_putchar('\n');
}
}

__attribute__((noreturn)) void FaultIrq(volatile ExcContext& context)
{
#if !defined(CPU_M0)
    int cfsr = SCB->CFSR;
    int shcsr = SCB->SHCSR;
    int bfar = SCB->BFAR;
    int mmfar = SCB->MMFAR;
    int pc = context.pc;    //fault pc

    printString("#### Fault\n");
    printInt(pc);
    printInt(cfsr);
    printInt(shcsr);
    printInt(bfar);
    printInt(mmfar);
    printInt(context.r0);
    printInt(context.r1);
    printInt(context.r2);
    printInt(context.r3);
#endif
    Hang();
}

void NmiHandler(volatile ExcContext&)
{
    Hang();
}

__attribute__((weak)) void Irq0Handler(volatile ExcContext&)
{
    Hang();
}

extern "C" __attribute__((used)) void InterruptHandlerImpl(IRQn_Type irq, volatile ExcContext& context)
{
    switch (irq)
    {
        case Nmi:
            NmiHandler(context);
            break;
        case Irq0:
#if defined(FPGA)
        case HactarIrq:
#endif
            Irq0Handler(context);
            break;
        case HardFault:
        case MemoryManagement:
        case BusFault:
        case UsageFault:
            FaultIrq(context);
            break;
        case Reset:
        case SVCall:
        case DebugMonitor:
        case PendSV:
        case SysTick_IRQn:
            break;
        default:
            Hang();
            break;
    }
}

extern "C" __attribute__((interrupt("IRQ"), naked)) void InterruptHandler()
{
    __ASM volatile("mrs r0, ipsr            \n"    // Read IPSR (Exceptio number)
                   "sub r0, #16             \n"    // Get it into IRQn_Type range
                   "tst lr, #4              \n"    // Select the stack which was in use
                   "ite eq                  \n"
                   "mrseq r1, msp           \n"
                   "mrsne r1, psp           \n"
                   "push {lr}               \n"    // Careful not to loose the EXC_RETURN value
                   "bl InterruptHandlerImpl \n"    // Handle the exception
                   "pop {pc}                \n");
}
