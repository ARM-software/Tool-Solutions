/*
 * Auto generated Run-Time-Environment Component Configuration File
 *      *** Do not modify ! ***
 *
 * Project: rtx5_m35_hello
 * RTE configuration: rtx5_m35_hello.rteconfig
*/
#ifndef RTE_COMPONENTS_H
#define RTE_COMPONENTS_H

/*
 * Define the Device Header File:
*/
#if defined( ARMCM35P )
    #define CMSIS_device_header "ARMCM35P.h"
#elif defined( ARMCM35P_TZ )
    #define CMSIS_device_header "ARMCM35P_TZ.h"
#elif defined( ARMCM35P_DSP_FP )
    #define CMSIS_device_header "ARMCM35P_DSP_FP.h"
#elif defined( ARMCM35P_DSP_FP_TZ )
    #define CMSIS_device_header "ARMCM35P_DSP_FP_TZ.h"
#else
    #error "Failed to specify device header for target"
#endif

#define RTE_CMSIS_RTOS2                 /* CMSIS-RTOS2 */
#define RTE_CMSIS_RTOS2_RTX5            /* CMSIS-RTOS2 Keil RTX5 */
#define RTE_CMSIS_RTOS2_RTX5_SOURCE     /* CMSIS-RTOS2 Keil RTX5 Source */

#ifdef KERNEL_NS
    #define RTE_CMSIS_RTOS2_RTX5_ARMV8M_NS  /* TZ context extensions */
#endif

#endif /* RTE_COMPONENTS_H */
