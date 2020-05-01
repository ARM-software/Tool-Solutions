/*
 * Copyright (c) 2020 Arm Limited. All rights reserved.
 */

#include <stdio.h>
#include "cmsis_os2.h"
#include "ARMCM33.h"
#include "core_cm33.h"

static const uint32_t external_counter_base_addr = 0x21000000;
static uint32_t * const external_counter_base    = (uint32_t*)external_counter_base_addr;
static const uint32_t counter_value              = 5000000;
static const uint32_t counter_enable             = 1;
static const uint32_t counter_register_addr_offset = 2;
static const uint32_t control_register_addr_offset = 0;
static const uint32_t status_register_addr_offset = 1;

void periodicTimerCallback(void *argument);
void oneShotTimerCallback(void *argument);
void app_main (void *argument);

osTimerId_t tidPeriodic;
osTimerId_t tidOneShot;

void periodicTimerCallback(void *argument) {
    printf("Periodic Timer hit\n");
}

void oneShotTimerCallback(void *argument) {
    printf("One shot Timer hit\n");
    uint32_t * const counter_addr = (external_counter_base + counter_register_addr_offset);
    *counter_addr = counter_value;
    uint32_t * const control_addr = (external_counter_base + control_register_addr_offset);
    *control_addr = counter_enable;
}

void app_main (void *argument) {	
    tidPeriodic = osTimerNew(periodicTimerCallback, osTimerPeriodic, NULL, NULL);
    tidOneShot  = osTimerNew(oneShotTimerCallback,  osTimerOnce,     NULL, NULL);

    osTimerStart(tidPeriodic, 100);
    osTimerStart(tidOneShot, 2000);
    while(1);
}

void externalInterruptHandler(void)
{
    printf("External interrupt handler called \n");
    uint32_t * const status_addr = (external_counter_base + status_register_addr_offset);
    *status_addr = 1; /* write 1 to clean interrupt and status register */
}

void setupExternalInterrupt(unsigned irq_no)
{
    NVIC_SetVector(irq_no, (uint32_t)(&externalInterruptHandler));
    NVIC_EnableIRQ(irq_no);
    __enable_irq();
    printf("External Interrupt Enabled \n");
}

int main (void) {
    osKernelInitialize();
    osThreadNew(app_main, NULL, NULL);
    setupExternalInterrupt(30);
    osKernelStart();
}
