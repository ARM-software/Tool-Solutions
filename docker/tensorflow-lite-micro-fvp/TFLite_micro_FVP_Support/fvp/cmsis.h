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

#pragma once

#include <cstddef>
#include <cstdint>

typedef enum
{
    Reset            = -15,
    Nmi              = -14,
    HardFault        = -13,
    MemoryManagement = -12,
    BusFault         = -11,
    UsageFault       = -10,
    SVCall           = -5,
    DebugMonitor     = -4,
    PendSV           = -2,
    SysTick_IRQn     = -1,
    Irq0             = 0,
#if defined(FPGA)
#if defined(CPU_M55)
    HactarIrq        = 55
#else
    HactarIrq        = 67
#endif
#else
    HactarIrq        = Irq0
#endif
} IRQn_Type;

#if defined(CPU_M55)
#define __ARMv81MML_REV           0x0001U   /* Core revision r0p1 */
#define __SAUREGION_PRESENT       1U        /* SAU regions present */
#define __MPU_PRESENT             1U        /* MPU present */
#define __VTOR_PRESENT            1U        /* VTOR present */
#define __NVIC_PRIO_BITS          3U        /* Number of Bits used for Priority Levels */
#define __Vendor_SysTickConfig    0U        /* Set to 1 if different SysTick Config is used */
#define __FPU_PRESENT             1U        /* FPU present */
#define __FPU_DP                  1U        /* double precision FPU */
#define __DSP_PRESENT             1U        /* DSP extension present */
#define __MVE_PRESENT             1U        /* MVE extensions present */
#define __MVE_FP                  1U        /* MVE floating point present */
#else
#define __CM7_REV 0x0000U
#define __FPU_PRESENT 0
#define __MPU_PRESENT 1
#define __ICACHE_PRESENT 1
#define __DCACHE_PRESENT 1
#define __TCM_PRESENT 0
#define __NVIC_PRIO_BITS 3
#define __Vendor_SysTickConfig 0
#endif

#define UNUSED(x) (void)(x)

#if defined(CPU_M7)
#include <core_cm7.h>
#elif defined(CPU_M4)
#include <core_cm4.h>
#elif defined(CPU_M3)
#include <core_cm3.h>
#elif defined(CPU_M0)
#include <core_cm0.h>
#elif defined(CPU_M33)
#include <core_cm33.h>
#elif defined(CPU_M55)
#include <core_armv81mml.h>
#else
#error "Unknown CPU"
#endif

// https://github.com/ARM-software/CMSIS_5/issues/532
#undef ARM_MPU_ACCESS_NORMAL
#define ARM_MPU_ACCESS_NORMAL(OuterCp, InnerCp, IsShareable)                                                           \
    ARM_MPU_ACCESS_((4U | (OuterCp)), IsShareable, ((InnerCp) >> 1), ((InnerCp)&1U))

namespace
{

constexpr uint32_t CountLeadingZeros(uint32_t x)
{
#if defined(__GNUC__)
    return static_cast<uint32_t>(__builtin_clz(x));
#else
    uint32_t mask    = 0x80000000U;
    uint32_t counter = 0;
    while ((mask & x) == 0)
    {
        ++counter;
        mask = mask >> 1;
    }
    return counter;
#endif
}

#if defined(CPU_M7)
namespace Mpu
{
inline void Enable()
{
    ARM_MPU_Enable(0);
}

inline void Disable()
{
    ARM_MPU_Disable();
}

inline void EnableRegion(const ARM_MPU_Region_t& regionConfig)
{
    ARM_MPU_SetRegion(regionConfig.RBAR, regionConfig.RASR);
}

inline void DisableRegion(unsigned regionNbr)
{
    ARM_MPU_ClrRegion(regionNbr);
}

inline void BootConfig()
{
#if 0
    // clang-format off
    constexpr ARM_MPU_Region_t initConfig[] = {
        // Main memory: firmware instructions
        {ARM_MPU_RBAR(0, 0x00000000), ARM_MPU_RASR_EX(0, ARM_MPU_AP_RO, ARM_MPU_ACCESS_NORMAL(ARM_MPU_CACHEP_WT_NWA, ARM_MPU_CACHEP_WT_NWA, 0), 0, ARM_MPU_REGION_SIZE_512MB)},
        // ACC interface to engine SRAMs
        {ARM_MPU_RBAR(1, 0x20000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_FULL, ARM_MPU_ACCESS_NORMAL(ARM_MPU_CACHEP_WB_WRA, ARM_MPU_CACHEP_WB_WRA, 0), 0, ARM_MPU_REGION_SIZE_512MB)},
        // ACC interface to control registers
        {ARM_MPU_RBAR(2, 0x40000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_FULL, ARM_MPU_ACCESS_DEVICE(0), 0, ARM_MPU_REGION_SIZE_512MB)},
        // Main memory: working data (read-write)
        {ARM_MPU_RBAR(3, 0x60000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_FULL, ARM_MPU_ACCESS_NORMAL(ARM_MPU_CACHEP_WB_WRA, ARM_MPU_CACHEP_WB_WRA, 0), 0, ARM_MPU_REGION_SIZE_512MB)},
        // Main memory: command stream
        {ARM_MPU_RBAR(4, 0x80000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_FULL, ARM_MPU_ACCESS_NORMAL(ARM_MPU_CACHEP_WB_WRA, ARM_MPU_CACHEP_WB_WRA, 1), 0, ARM_MPU_REGION_SIZE_512MB)},
        // Unused
        {ARM_MPU_RBAR(5, 0xA0000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_NONE, ARM_MPU_ACCESS_DEVICE(1), 0, ARM_MPU_REGION_SIZE_512MB)},
        // Unused
        {ARM_MPU_RBAR(6, 0xC0000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_NONE, ARM_MPU_ACCESS_DEVICE(0), 0, ARM_MPU_REGION_SIZE_512MB)},
        // PPB
        {ARM_MPU_RBAR(7, 0xE0000000), ARM_MPU_RASR_EX(1, ARM_MPU_AP_URO, ARM_MPU_ACCESS_ORDERED, 0, ARM_MPU_REGION_SIZE_512MB)},
    };
    // clang-format on
    constexpr unsigned regionCnt = sizeof(initConfig) / sizeof(ARM_MPU_Region_t);
    static_assert(regionCnt == 8, "Number of regions must be 8");
    ARM_MPU_Load(initConfig, regionCnt);
#endif
}
}    // namespace Mpu

namespace Cache
{
inline void DClean(const void* addr, ptrdiff_t dsize)
{
    auto paddr = const_cast<uint32_t*>(reinterpret_cast<const uint32_t*>(addr));
    SCB_CleanDCache_by_Addr(paddr, dsize);
}

inline void DClean(const void* beg, const void* end)
{
    ptrdiff_t dsize = reinterpret_cast<const uint8_t*>(end) - reinterpret_cast<const uint8_t*>(beg);
    DClean(beg, dsize);
}

inline void DClean()
{
    SCB_CleanDCache();
}

inline void DInvalidate(void* addr, ptrdiff_t dsize)
{
    auto paddr = reinterpret_cast<uint32_t*>(addr);
    SCB_InvalidateDCache_by_Addr(paddr, dsize);
}

inline void DInvalidate(void* beg, void* end)
{
    ptrdiff_t dsize = reinterpret_cast<uint8_t*>(end) - reinterpret_cast<uint8_t*>(beg);
    DInvalidate(beg, dsize);
}

inline void DInvalidate()
{
    SCB_InvalidateDCache();
}

inline void DCleanInvalidate(void* addr, ptrdiff_t dsize)
{
    auto paddr = reinterpret_cast<uint32_t*>(addr);
    SCB_CleanInvalidateDCache_by_Addr(paddr, dsize);
}

inline void DCleanInvalidate(void* beg, void* end)
{
    ptrdiff_t dsize = reinterpret_cast<uint8_t*>(end) - reinterpret_cast<uint8_t*>(beg);
    DCleanInvalidate(beg, dsize);
}

inline void DCleanInvalidate()
{
    SCB_CleanInvalidateDCache();
}

inline void IEnable()
{
    SCB_EnableICache();
}

inline void IDisable()
{
    SCB_DisableICache();
}

inline void DEnable()
{
    SCB_EnableDCache();
}

inline void DDisable()
{
    SCB_DisableDCache();
}
}    // namespace Cache
#endif

#if !defined(CPU_M0)
namespace Dwt
{
inline void Reset()
{
    CoreDebug->DEMCR |= 0x01000000;
    DWT->CYCCNT   = 0;    // reset the cycle counter
    DWT->SLEEPCNT = 0;    // reset the sleep counter
    DWT->CTRL     = 0;
}

inline void Start()
{
    DWT->CTRL |= 0x00000001;    // enable the counter
}

inline void Stop()
{
    DWT->CTRL &= 0xFFFFFFFE;    // disable the counter
}

inline uint8_t GetSleepCycleCount()
{
    return static_cast<uint8_t>(DWT->SLEEPCNT);
}

inline uint32_t GetCycleCount()
{
    return DWT->CYCCNT;
}

}    // namespace Dwt
#endif
}    // namespace
