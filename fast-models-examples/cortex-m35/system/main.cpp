/*
 * Copyright (c) 2022 Arm Limited. All rights reserved.
 */

#include <scx_evs_m35.h>
#include <amba_pv.h> 
#include "external_counter.h"

int sc_main(int argc, char *argv[])
{
    double quantum = 10000.0;
    double latency = 100.0;

    scx::scx_initialize("m35");
	/* scx::scx_initialize("m35", scx::scx_get_default_simcontrol()); */

	scx_evs_m35 cortex_m35_subsystem("cortex-m35-subsystem");
    external_counter<64> ext_counter("ext_counter"); 

    cortex_m35_subsystem.m_port_to_external_counter(ext_counter.amba_pv_s);
    ext_counter.irq_out(cortex_m35_subsystem.slave_counter_irq_in); 

    /* Simulation quantum, i.e. seconds to run per quantum */
    tlm::tlm_global_quantum::instance().set(sc_core::sc_time(quantum
                                                             / 100000000.0,
                                                             sc_core::SC_SEC));
 
    /* Simulation minimum synchronization latency */
    scx::scx_set_min_sync_latency(latency / 100000000.0);

    /* From command-line options... */
    scx::scx_parse_and_configure(argc, argv, "");

    sc_core::sc_start();

    return 0;
}
