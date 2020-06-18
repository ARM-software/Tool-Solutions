/*
 * main.cpp - DualDhrystone platform model wrapper.
 *
 * Copyright 2011-2013 ARM Limited.
 * All rights reserved.
 */

/* Includes */
#include <scx_evs_EVS_Cortex_M4.h>
#include <scx_evs_EVS_Cortex_M0Plus.h>
#include <Mailbox.h>

/* Data types */

/* Functions */

/*
 * User's entry point.
 */
int sc_main(int argc , char * argv[]) {

    /*
     * Initialize simulation 
     */
    scx::scx_initialize("DualCortexM");

    /*
     * Components
     */

	scx_evs_EVS_Cortex_M4 Cortex_M4("Cortex_M4");
	scx_evs_EVS_Cortex_M0Plus Cortex_M0Plus("Cortex_M0Plus");
        Mailbox Mailbox("Mailbox");

	/*  
	* Memories
	* Cortex-M4 has separate iram/dram
	* Cortex-M0+ has common iram/dram
	* Shared dram
	*/

	amba_pv::amba_pv_memory<64> M4_iram("M4_iram", 0x1FFFF); 
	amba_pv::amba_pv_memory<64> M4_dram("M4_dram", 0x1FFFF);
	amba_pv::amba_pv_memory<64> M0Plus_idram("M0Plus_idram", 0x1FFFF);
	amba_pv::amba_pv_memory<64> shared_dram("shared_dram", 0x3FFFF);

	/*
	* amba_pv_decoder is a SystemC component that can combine or split buses.  we are using it here to split
	* the bus from the CPUs and - where needed - combine the buses connecting to a memory bus slave port.
	*
	* amba_pv_decoder<width, inputs, outputs>, i.e.
	* amba_pv_decoder<64, 2, 1> 64-bit wide bus, with 2 inputs and 1 output(a "funnel")
	* amba_pv_decoder<64, 1, 4> 64-bit wide bus, with 2 inputs and 1 output(a "splitter")
	*
	* M4_splitter splits the bus to 4 target slaves (iram, dram, shared dram, Mailbox)
	* M0Plus_splitter splits the bus to 3 target slaves (i/d ram, shared dram, Mailbox)
	* shared_dram_funnel merges the buses from the 2 CPUs to the shared dram
	* shared_mailbox_funnel erges the buses from the 2 CPUs to the mailnox amba slave port
	*/

	amba_pv::amba_pv_decoder<64, 2, 1> shared_dram_funnel("shared_dram_funnel");
	amba_pv::amba_pv_decoder<64, 2, 1> shared_mailbox_funnel("shared_mailbox_funnel");
	amba_pv::amba_pv_decoder<64, 1, 4> M4_splitter("M4_splitter");
	amba_pv::amba_pv_decoder<64, 1, 3> M0Plus_splitter("M0Plus_splitter");

    /*
     * Simulation configuration
     */
   
    /* From command-line options */
    scx::scx_parse_and_configure(argc, argv);

    /* Semi-hosting configuration */
    	scx::scx_set_parameter("*.Core.semihosting-enable", true);
    	scx::scx_set_parameter("*.Core.semihosting-Thumb_SVC", 0xAB);
    	scx::scx_set_parameter("*.Core.semihosting-heap_base", 0x0);
	scx::scx_set_parameter("*.Core.semihosting-heap_limit", 0x10700000);
	scx::scx_set_parameter("*.Core.semihosting-stack_base", 0x10700000);
	scx::scx_set_parameter("*.Core.semihosting-stack_limit", 0x10800000);

    /* Simulation quantum, i.e. seconds to run per quantum */
    tlm::tlm_global_quantum::instance().set(sc_core::sc_time(100.0
                                                             / 100000000,
                                                             sc_core::SC_SEC));

    /* Simulation minimum synchronization latency */
    scx::scx_set_min_sync_latency(100.0 / 100000000);

    /* 
    * Bindings 
    */

    /* 
    * Connect the cores to the bus splitters
    */
	
    Cortex_M4.amba_pv_m(M4_splitter.amba_pv_s[0]);
    Cortex_M0Plus.amba_pv_m(M0Plus_splitter.amba_pv_s[0]);

    /* 
    * Connect the splitters to their targets
    */

    M4_splitter.bind(0, M4_iram.amba_pv_s, 0x00000000ull, 0x1ffffull);
    M4_splitter.bind(1, M4_dram.amba_pv_s, 0x20000000ull, 0x2001ffffull);
    M4_splitter.bind(2, shared_dram_funnel.amba_pv_s[0], 0x20100000ull, 0x2013ffffull);
    M4_splitter.bind(3, shared_mailbox_funnel.amba_pv_s[0], 0x40000000ull, 0x40000007ull);
    M0Plus_splitter.bind(0, M0Plus_idram.amba_pv_s, 0x00000000ull, 0x1ffffull);
    M0Plus_splitter.bind(1, shared_dram_funnel.amba_pv_s[1], 0x20100000ull, 0x2013ffffull);
    M0Plus_splitter.bind(2, shared_mailbox_funnel.amba_pv_s[1], 0x40000000ull, 0x40000007ull);	

    /* 
    * Connect the funnels to the shared memories
    */
	
    shared_dram_funnel.bind(0, shared_dram.amba_pv_s, 0x00000000ull, 0x3ffffull);
    shared_mailbox_funnel.bind(0, Mailbox.amba_pv_s, 0x00000000ull, 0x00000007ull);
 
    /* 
    * Connect the irq signals to the shared memories
    */

    Mailbox.irqa_signal(Cortex_M4.irq_in_s);
    Mailbox.irqb_signal(Cortex_M0Plus.irq_in_s);

    /*
     * Start of simulation
     */

    sc_core::sc_start();
    return EXIT_SUCCESS;
}
