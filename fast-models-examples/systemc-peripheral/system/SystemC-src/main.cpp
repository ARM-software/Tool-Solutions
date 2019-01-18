/*
 * main.cpp - Example Cortex-A53 system with SystemC UART
 *
 * Copyright 2011-2019 ARM Limited.
 * All rights reserved.
 */

/* Includes */
#include <scx_evs_a53x1.h>
#include "pl011_uart.h"
#include "tterm.h"
#include "fterm.h"


/*
 * User's entry point.
 */
int sc_main(int argc , char * argv[]) {

    /*
     * Initialize simulation 
     */
    scx::scx_initialize("a53x1");

    /*
     * Components
     */
    scx_evs_a53x1  a53x1("a53x1");
    amba_pv::amba_pv_to_tlm_bridge<64> amba2tlm("amba2tlm");
    pl011_uart  uart("uart");
    amba_pv::signal_from_sc_bridge<bool> sc2sig("sc2sig");
    sc_signal<bool>  interrupt;
    
    // NOTE: select 1 of the 2 possible terminal models:
    //       refer to the source code for the parameter values
    // Uncomment the tterm model for a full terminal with xterm or telnet
    tterm       term("term", true);
    // Uncomment the fterm for simple file I/O (no input)
    //fterm       term("term", true, false);

    /*
     * Simulation configuration
     */
   
    /* From command-line options */
    scx::scx_parse_and_configure(argc, argv);

    /* Simulation quantum, i.e. seconds to run per quantum */
    tlm::tlm_global_quantum::instance().set(sc_core::sc_time(100.0
                                                             / 100000000,
                                                             sc_core::SC_SEC));

    /* Simulation minimum synchronization latency */
    scx::scx_set_min_sync_latency(100.0 / 100000000);

    /*
     * Bindings
     */
    a53x1.amba_pv_m(amba2tlm.amba_pv_s);
    amba2tlm.tlm_m.bind(uart.bus);
    uart.tx(term.rx);
    term.tx(uart.rx);
    uart.intr(interrupt);
    sc2sig.signal_in(interrupt);
    sc2sig.signal_m(a53x1.uart_intr);
    
    /*
     * Start of simulation
     */
    sc_core::sc_start();
    return EXIT_SUCCESS;
}
