/*
 * main.cpp - Example Cortex-55 system with SystemC peripheral
 *
 * Copyright 2011-2019 ARM Limited.
 * All rights reserved.
 */

/* Includes */
#include <scx_evs_m55.h>
#include "trickbox.h"


/*
 * User's entry point.
 */
int sc_main(int argc , char * argv[]) {

    /*
     * Initialize simulation 
     */
    scx::scx_initialize("m55");

    /*
     * Components
     */
    scx_evs_m55  m55("m55");
    amba_pv::amba_pv_to_tlm_bridge<64> amba2tlm("amba2tlm");
    trickbox  trickbox("trickbox");
    
    /*
     * Simulation configuration
     */
   
    /* From command-line options */
    scx::scx_parse_and_configure(argc, argv);

    /* Simulation quantum, i.e. seconds to run per quantum */
    tlm::tlm_global_quantum::instance().set(sc_core::sc_time(1.0
                                                             / 100000000,
                                                             sc_core::SC_SEC));

    /* Simulation minimum synchronization latency */
    scx::scx_set_min_sync_latency(1.0 / 100000000);

    /*
     * Bindings
     */
    m55.amba_pv_m(amba2tlm.amba_pv_s);
    amba2tlm.tlm_m.bind(trickbox.bus);
    
    /*
     * Start of simulation
     */
    sc_core::sc_start();
    return EXIT_SUCCESS;
}
