/*
 * main.cpp - Cortex-M0Plus platform model wrapper with support for setting the
 *            quantum.
 *
 * Copyright 2012-2020 ARM Limited.
 * All rights reserved.
 */

/* Includes */
#include <cstring>
#include <cstdlib>

#include <scx_evs_EVS_Cortex_M0Plus.h>

/* Globals */

static const char help_quantum[] =
    "-Q, --quantum N            "
    "number of ticks to simulate per quantum (default to 10000)\n"
    "-M, --min-sync-latency N   "
    "Number of ticks to simulate before synchronizing. Events occurring\n"
    "                           at a higher frequency than this are missed\n"
    "                           (default to 100)\n";
static double quantum = 10000.0;
static double latency = 100.0;

/* Functions */

/*
 * Specific command-line options parsing
 */
static void parse_quantum(int & argc , char * argv[]) {
    int j = 1;

    for (int i = 1; (i < argc); i += 1) {
        if ((std::strcmp(argv[i], "-Q") == 0)
            || (std::strncmp(argv[i], "-Q=", 3) == 0)
            || (std::strcmp(argv[i], "--quantum") == 0)
            || (std::strncmp(argv[i], "--quantum=", 10) == 0)) {

            /* number of instructions to run per quantum */
            const char * p = strchr(argv[i], '=');

            if (p == NULL) {
                if ((i + 1) >= argc) {
                    std::cerr << argv[0] << ": option '" << argv[i]
                              << "' requires an argument\n";
                    std::exit(EXIT_FAILURE);
                }
                i += 1;
                quantum = std::atol(argv[i]);
            } else {
                quantum = std::atol(p + 1);
            }
            continue;
        }
        if ((std::strcmp(argv[i], "-M") == 0)
            || (std::strncmp(argv[i], "-M=", 3) == 0)
            || (std::strcmp(argv[i], "--min-sync-latency") == 0)
            || (std::strncmp(argv[i], "--min-sync-latency=", 19) == 0)) {

            /* number of instructions to run before synchronizing */
            const char * p = strchr(argv[i], '=');

            if (p == NULL) {
                if ((i + 1) >= argc) {
                    std::cerr << argv[0] << ": option '" << argv[i]
                              << "' requires an argument\n";
                    std::exit(EXIT_FAILURE);
                }
                i += 1;
                latency = std::atol(argv[i]);
            } else {
                latency = std::atol(p + 1);
            }
            continue;
        }
        argv[j] = argv[i];
        j += 1;
    }
    for (int i = j; (i < argc); i += 1){
        argv[i] = nullptr;
    }
    argc = j;
}

/*
 * User's entry point.
 */
int sc_main(int argc , char * argv[]) {

    /*
     * Initialize simulation 
     */
    scx::scx_initialize("Cortex_M0Plus");

    /*
     * Components
     */
    amba_pv::amba_pv_memory<64> memory("Memory", 0xFFFFFFFF);
	scx_evs_EVS_Cortex_M0Plus Cortex_M0Plus("Cortex_M0Plus");

    /*
     * Number of instructions to run per quantum, latency
     */
    parse_quantum(argc, argv);

    /*
     * Simulation configuration
     */

    /* From command-line options */
    scx::scx_parse_and_configure(argc, argv, help_quantum);
   
    /* Semi-hosting configuration */

    scx::scx_set_parameter("*.Core.semihosting-enable", true);
    scx::scx_set_parameter("*.Core.semihosting-Thumb_SVC", 0xAB);
    scx::scx_set_parameter("*.Core.semihosting-heap_base", 0x0);
    scx::scx_set_parameter("*.Core.semihosting-heap_limit", 0x10700000);
    scx::scx_set_parameter("*.Core.semihosting-stack_base", 0x10700000);
    scx::scx_set_parameter("*.Core.semihosting-stack_limit", 0x10800000);

    /* Simulation quantum, i.e. seconds to run per quantum */
    tlm::tlm_global_quantum::instance().set(sc_core::sc_time(quantum
                                                             / 100000000,
                                                             sc_core::SC_SEC));

    /* Simulation minimum synchronization latency */
    scx::scx_set_min_sync_latency(latency / 100000000);

    /*
     * Bindings
     */
    Cortex_M0Plus.amba_pv_m(memory.amba_pv_s);

    /*
     * Start of simulation
     */
    sc_core::sc_start();
    return EXIT_SUCCESS;
}
