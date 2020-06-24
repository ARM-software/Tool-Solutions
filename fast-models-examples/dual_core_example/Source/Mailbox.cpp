/*
 * SystemC Mailbox component implementation
 *
 * Copyright 2007-2020 ARM Limited.
 * All rights reserved
 */

/* Includes */

#include "Mailbox.h"

/* Constants */

/*
 * Register relative addresses
 */
const sc_dt::uint64 Mailbox::Register1_ADDR = 0x00;  /* First register */
const sc_dt::uint64 Mailbox::Register2_ADDR = 0x04;  /* First register */


/* Functions */

/*
 * Constructor
 */
Mailbox::Mailbox
			(sc_core::sc_module_name module_name,
			bool enable_dmi,
			bool verbose):
			sc_core::sc_module(module_name),
			amba_pv::amba_pv_slave_base<BUSWIDTH>(name()),
			amba_pv_s("amba_pv_s")
			
			{
				amba_pv_s(* this);
				dont_initialize();
				std::cout << name() << " module created\n";
				Register1=0x12345678;
				Register2=0x12345678;
}

/*
 * Destructor.
 */
Mailbox::~Mailbox() {
   
}


/*
 * Read access
 */
amba_pv::amba_pv_resp_t Mailbox::read(int socket_id,
                                  const sc_dt::uint64 & addr,
                                  unsigned char * data,
                                  unsigned int size,
                                  const amba_pv::amba_pv_control * ctrl,
                                  sc_core::sc_time & t) {
    switch (addr) {      
        case Register1_ADDR:
			std::cout << "**DEBUG** " << name() << ": Received read request "
					  << "at address: " << std::showbase << std::hex << "0x" 
					  << addr << std::endl;
			(* reinterpret_cast <unsigned int *> (data)) = Mailbox::Register1;
			
			std::cout << "**DEBUG** " << name() << ": Clearing interrupt signal to CPU2\n\n" << std::endl;

			//Call scx_sync() to break the quantum now
			scx::scx_sync(0);

			//Set IRQ signal Low
			irqb_signal.set_state(false);
			
			break;

        case Register2_ADDR:
			std::cout << "**DEBUG** " << name() << ": Received read request "
					  << "at address: " << std::showbase << std::hex << "0x" 
					  << addr << std::endl;
			(* reinterpret_cast <unsigned int *> (data)) = Mailbox::Register2;
			
			std::cout << "**DEBUG** " << name() << ": Clearing interrupt signal to CPU1\n\n" << std::endl;

			//Call scx_sync() to break the quantum now
			scx::scx_sync(0);

			//Set IRQ signal Low
			irqa_signal.set_state(false);

			break;

        default:       
            std::cout << "**ERROR** " << name() << ": received read request"
                      << " with input address out of range: "
                      << std::showbase << std::hex << addr << std::endl;
            return (amba_pv::AMBA_PV_SLVERR);
    }
    return (amba_pv::AMBA_PV_OKAY);
}

/*
 * Write access
 */
amba_pv::amba_pv_resp_t Mailbox::write(int socket_id,
                                   const sc_dt::uint64 & addr,
                                   unsigned char * data,
                                   unsigned int size,
                                   const amba_pv::amba_pv_control * ctrl,
                                   unsigned char * strb,
                                   sc_core::sc_time & t) {

    switch (addr) {
        case Register1_ADDR:
			std::cout << "**DEBUG** " << name() << ": Received write request "
					  << "at address: " << std::showbase << std::hex << "0x" 
					  << addr << std::endl;

			std::cout << "**DEBUG** " << name() << ": Asserting interrupt signal for CPU 1" << std::endl;
				
			//Call scx_sync()to break the quantum now
			scx::scx_sync(0);

			//Set IRQ signal High
			irqa_signal.set_state(true);

            break;

        case Register2_ADDR:
			std::cout << "**DEBUG** " << name() << ": Received write request "
					  << "at address: " << std::showbase << std::hex << "0x" 
					  << addr << std::endl;

			std::cout << "**DEBUG** " << name() << ": Asserting interrupt signal for CPU 2" << std::endl;
				
			//Call scx_sync()to break the quantum now
			scx::scx_sync(0);

			//Set IRQ signal High
			irqb_signal.set_state(true);

            break;

        default: 
            std::cout << "**ERROR** " << name() << ": received write request "
                      << "with input address out of range: " << std::showbase
                      << std::hex << addr << std::endl;
            return (amba_pv::AMBA_PV_SLVERR);
    }
    return (amba_pv::AMBA_PV_OKAY);
}

/*
 * Debug read access
 */
unsigned int Mailbox::debug_read(int socket_id,
                             const sc_dt::uint64 & addr,
                             unsigned char * data,
                             unsigned int length,
                             const amba_pv::amba_pv_control * ctrl) {
    switch (addr) {      
        case Register1_ADDR:
			std::cout << "**DEBUG** " << name() << ": Sending IRQ signal to core 2"
					  << std::endl;
			return Mailbox::Register1;
            break;
        case Register2_ADDR:
			std::cout << "**DEBUG** " << name() << ": Sending IRQ signal to core 1"
					  << std::endl;
			return Mailbox::Register2;
            break;

        default:       
            return 0;
    }
    return (length);
}

/*
 * Debug write access
 */
unsigned int Mailbox::debug_write(int socket_id,
                              const sc_dt::uint64 & addr,
                              unsigned char * data,
                              unsigned int length,
                              const amba_pv::amba_pv_control * ctrl) {
    switch (addr) {
        case Register1_ADDR:
            break;

        case Register2_ADDR:
            break;

        default: 
            return 0;
    }
    return (length);
}
