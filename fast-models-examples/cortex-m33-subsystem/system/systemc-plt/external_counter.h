/* name: external_counter.h
 * desc: Example external counter
 * Copyright (c) 2020 Arm Limited. All rights reserved.
 */
#ifndef EXTERNAL_COUNTER_H
#define EXTERNAL_COUNTER_H

#include <iostream>
#include "amba_pv.h"
#include "sockets/amba_pv_slave_socket.h"

using namespace amba_pv;

template<unsigned int BUSWIDTH = 64>
class external_counter:
    public sc_core::sc_module,
    public amba_pv_slave_base<BUSWIDTH>
{
    public:
        /* Constructor/Destructor */
        external_counter(sc_core::sc_module_name);
        ~external_counter();

        /* Ports */
        amba_pv_slave_socket<BUSWIDTH> amba_pv_s;
        signal_master_port<bool>       irq_out;

        /* Registers */
        static constexpr unsigned control_addr {0x0};
        static constexpr unsigned status_addr  {0x4};
        static constexpr unsigned counter_addr {0x8};

        uint32_t control{0};
        unsigned control_ctrl_bit_mask{1};
        uint32_t status{0};
        unsigned status_clr_bit_mask{1};
        uint32_t counter{0};

        /* sc_object overridables */
        virtual const char * kind() const;

        /* User-layer interface */
        virtual amba_pv_resp_t read(int,
                                    const sc_dt::uint64 &,
                                    unsigned char *,
                                    unsigned int,
                                    const amba_pv_control *,
                                    sc_core::sc_time &); 
        virtual amba_pv_resp_t write(int,
                                     const sc_dt::uint64 &,
                                     unsigned char *,
                                     unsigned int,
                                     const amba_pv_control *,
                                     unsigned char *,
                                     sc_core::sc_time &); 
        virtual bool get_direct_mem_ptr(int,
                                        tlm::tlm_command,
                                        const sc_dt::uint64 &,
                                        const amba_pv_control *,
                                        tlm::tlm_dmi &); 

         /* Debug interface */
         virtual unsigned int debug_read(int,
                                         const sc_dt::uint64 &,
                                         unsigned char *,
                                         unsigned int,
                                         const amba_pv_control *); 
         virtual unsigned int debug_write(int,
                                          const sc_dt::uint64 &,
                                          unsigned char *,
                                          unsigned int,
                                          const amba_pv_control *); 
    private:
         sc_core::sc_event checkCounterEvent{};
         void              triggerIrq();
};

template<unsigned int BUSWIDTH>
inline
external_counter<BUSWIDTH>::external_counter(sc_core::sc_module_name name):
    sc_core::sc_module(name),
    amba_pv_slave_base<BUSWIDTH>((const char *) name),
    amba_pv_s("amba_pv_s"),
    irq_out("irq_out")
{

    /* Bindings... */
    amba_pv_s(* this);
    SC_HAS_PROCESS(external_counter);
    SC_METHOD(triggerIrq);
    sensitive << checkCounterEvent;
    dont_initialize();
}

/*
 * Destructor.
 */
template<unsigned int BUSWIDTH>
inline
external_counter<BUSWIDTH>::~external_counter()
{
}

/*
 * Returns the kind string of this memory.
 */
template<unsigned int BUSWIDTH>
inline const char *
external_counter<BUSWIDTH>::kind() const
{
    return ("external_counter");
}

/*
 * Completes a read transaction
 */
template<unsigned int BUSWIDTH>
inline amba_pv_resp_t
external_counter<BUSWIDTH>::read(int socket_id,
                               const sc_dt::uint64 & addr,
                               unsigned char * data,
                               unsigned int size,
                               const amba_pv_control * ctrl,
                               sc_core::sc_time & t)
{
    std::cout << this->name() << ": call to read() for addr=" << addr << std::endl;
    switch(addr)
    {
        case control_addr:
            memcpy(data, &control, sizeof(uint32_t));
            break;
        case status_addr:
            memcpy(data, &status,  sizeof(uint32_t));
            break;
        case counter_addr:
            memcpy(data, &counter, sizeof(uint32_t));
            break;
        default:
            std::cout << this->name() << ": address not found" << std::endl;
    }
    return (AMBA_PV_OKAY);
}

/*
 * Completes a write transaction.
 */
template<unsigned int BUSWIDTH>
inline amba_pv_resp_t
external_counter<BUSWIDTH>::write(int socket_id,
                                const sc_dt::uint64 & addr,
                                unsigned char * data,
                                unsigned int size,
                                const amba_pv_control * ctrl,
                                unsigned char * strb,
                                sc_core::sc_time & t)
{
    std::cout << this->name() << ": call to write() for addr=" << addr << " value=" << *((uint32_t*)data) << std::endl;
    switch(addr)
    {
        case control_addr:
            memcpy(&control, data, sizeof(uint32_t));
            if(control & control_ctrl_bit_mask)
            {
                checkCounterEvent.notify(sc_core::sc_time(counter, sc_core::SC_NS));
            }
            break;
        case status_addr:
            memcpy(&status,  data,sizeof(uint32_t));
            if(status & status_clr_bit_mask)
            {
                control = 0;
                status  = 0;
                irq_out.set_state(false);
            }
            break;
        case counter_addr:
            memcpy(&counter,  data,sizeof(uint32_t));
            break;
        default:
            std::cout << this->name() << ": address not found" << std::endl;
    }
    return (AMBA_PV_OKAY);
}

/*
 * Non-intrusive debug read transaction.
 */
template<unsigned int BUSWIDTH>
inline unsigned int
external_counter<BUSWIDTH>::debug_read(int socket_id,
                                     const sc_dt::uint64& addr,
                                     unsigned char * data,
                                     unsigned int length,
                                     const amba_pv_control * ctrl)
{
    std::cout << this->name() << ": call to debug_read(), addr=0x"
              << std::hex << addr << std::endl;
    return 0;
}

/*
 * Non-intrusive debug write transaction.
 */
template<unsigned int BUSWIDTH>
inline unsigned int
external_counter<BUSWIDTH>::debug_write(int socket_id,
                                      const sc_dt::uint64 & addr,
                                      unsigned char * data,
                                      unsigned int length,
                                      const amba_pv_control * ctrl)
{
    std::cout << this->name() << ": call to debug_write(), addr=0x"
              << std::hex << addr << std::endl;
    return 0;
}

/*
 * Requests DMI access to the specified address and returns a reference to a
 * DMI descriptor.
 */
template<unsigned int BUSWIDTH>
inline bool
external_counter<BUSWIDTH>::get_direct_mem_ptr(int socket_id,
                                         tlm::tlm_command command,
                                         const sc_dt::uint64 & addr,
                                         const amba_pv_control * ctrl,
                                         tlm::tlm_dmi & dmi_data)
{
    return false;
}

template<unsigned int BUSWIDTH>
inline void
external_counter<BUSWIDTH>::triggerIrq()
{
    std::cout << "IrqOut " << std::endl;
    status = 1;
    irq_out.set_state(true);
}
#endif /* EXTERNAL_COUNTER_H */
