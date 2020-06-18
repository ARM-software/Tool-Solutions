/*
 * SystemC Mailbox component implementation.
 *
 * Copyright 2007-2020 ARM Limited.
 * All rights reserved.
 *
 */

/* Includes */ 
#include <amba_pv.h>
#include "scx/scx.h"
#include "types.h"

/* Datatypes */

class Mailbox: 
    public sc_core::sc_module,
    public amba_pv::amba_pv_slave_base<BUSWIDTH> {
      
    /* Registers relative addresses */
    public:
        static const sc_dt::uint64 Register1_ADDR;
	static const sc_dt::uint64 Register2_ADDR;

	int Register1;
	int Register2;


    /* Module ports */
        amba_pv::amba_pv_slave_socket<64> amba_pv_s;
	amba_pv::signal_master_port<bool> irqa_signal;
	amba_pv::signal_master_port<bool> irqb_signal;

    /* Constructor */
        explicit Mailbox(sc_core::sc_module_name, bool = false, bool = false);
        virtual ~Mailbox();

    /* User-layer interface */
    protected:
        virtual amba_pv::amba_pv_resp_t
        read(int,
             const sc_dt::uint64 &,
             unsigned char *,
             unsigned int,
             const amba_pv::amba_pv_control *,
             sc_core::sc_time &);
        virtual amba_pv::amba_pv_resp_t
        write(int,
              const sc_dt::uint64 &,
              unsigned char *,
              unsigned int,
              const amba_pv::amba_pv_control *,
              unsigned char *,
              sc_core::sc_time &);
        virtual unsigned int
        debug_read(int,
                   const sc_dt::uint64 &,
                   unsigned char *,
                   unsigned int,
                   const amba_pv::amba_pv_control *);
        virtual unsigned int
        debug_write(int,
                    const sc_dt::uint64 &,
                    unsigned char *,
                    unsigned int,
                    const amba_pv::amba_pv_control *);

};


