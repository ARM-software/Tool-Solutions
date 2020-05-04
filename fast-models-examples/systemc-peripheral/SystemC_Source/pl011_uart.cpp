/*
** Copyright (c) 2019 Arm Limited. All rights reserved.
*/


#include "pl011_uart.h"

pl011_uart::pl011_uart(sc_core::sc_module_name  name) :
  sc_module(name),
    bus("bus"),
    tx("tx"),
    intr("intr")
{
    SC_HAS_PROCESS(pl011_uart);

    SC_THREAD(intrThread);

    // Set up the method for the terminal side (statically sensitive to Rx)
    SC_METHOD(rxMethod);
    sensitive << rx;
    dont_initialize();

    // Register the blocking transport method
    bus.register_b_transport(this, &pl011_uart::busReadWrite);

    // register the debug function
    bus.register_transport_dbg(this, &pl011_uart::transport_dbg);

    // Clear UART regs
    memset(&regs, 0, sizeof(regs));

    // Set initial values
    regs.uartFR = 0x90;
    regs.uartCR = 0x300;
    regs.uartIFLS = 0x12;
    regs.uartID0 = 0x11;
    regs.uartID1 = 0x10;
    regs.uartID2 = 0x14;
    regs.uartID3 = 0x0;
    regs.uartID4 = 0xd;
    regs.uartID5 = 0xf0;
    regs.uartID6 = 0x5;
    regs.uartID7 = 0xb1;

    memset(&read_struct, 0, sizeof(read_struct));

    read_struct.read_trigger = 1;

    std::cout << "Completed pl011 constructor" << std::endl;
}

void
pl011_uart::uart_update()
{
    uint32_t flags;
    bool interrupt = false;

    flags = regs.uartRIS & regs.uartIMSC;

    if (flags)
        interrupt = true;;

    intrQueue.write(interrupt);
}

void
pl011_uart::rxMethod()
{

    int   slot;

    slot = read_struct.read_pos + read_struct.read_count;
    if (slot >= 16)
        slot -= 16;
    read_struct.read_fifo[slot] = rx.read();
    read_struct.read_count++;

    clr(regs.uartFR, 0x10); // clear RXFE

    if ((isClr(regs.uartLCR_H, 0x10)) ||
         read_struct.read_count == 16) {
      set(regs.uartFR, 0x40); // set RXFF 
    }
    if (read_struct.read_count == read_struct.read_trigger) {
      set(regs.uartRIS, 0x10); // set RXRIS
      uart_update();
    }

}

void
pl011_uart::intrThread()
{
    intr.write(false); // Clear interrupt on startup
    while (true) 
    {
        // suspended by the Queue read operation
        bool q = intrQueue.read();
        intr.write(q);
    }
}


void
#ifdef MP_SOCKET
pl011_uart::busReadWrite(int tag, tlm::tlm_generic_payload &gp,
		         sc_core::sc_time         &delay)
#else
pl011_uart::busReadWrite(tlm::tlm_generic_payload &gp,
		         sc_core::sc_time         &delay)
#endif
{
    // Break out the address, mask and data pointer. This should be only a
    // single byte access.
    sc_dt::uint64      addr    = gp.get_address();

    //unsigned char     *maskPtr = gp.get_byte_enable_ptr();
    uint32_t          *dataPtr;
  
    int                offset;		// Data byte offset in word
    uint32_t           uaddr;		// UART address

    // Mask off the address to its range. This ought to have been done already
    // by an arbiter/decoder.
    uaddr = (uint32_t)(addr) & UART_ADDR_MASK;
    offset = 0;

    dataPtr = reinterpret_cast<uint32_t*>(gp.get_data_ptr());

    // Which command?
    switch(gp.get_command()) 
    {
        case tlm::TLM_READ_COMMAND:  
            dataPtr[offset] = busRead(uaddr); 
            break;
        case tlm::TLM_WRITE_COMMAND: 
            busWrite(uaddr, dataPtr[offset]); 
            break;
        case tlm::TLM_IGNORE_COMMAND:
            gp.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
            break;
            return;
    }

    gp.set_response_status(tlm::TLM_OK_RESPONSE);
    delay += sc_core::sc_time(10, SC_NS);

}

void
pl011_uart::uartDR_bus_read(
        uint32_t& data,
        sc_core::sc_time& delay)
{
    unsigned c;
    clr(regs.uartFR, 0x40); // clear RXFF
    c = read_struct.read_fifo[read_struct.read_pos];
    if (read_struct.read_count > 0) {
        read_struct.read_count--;
        if (++read_struct.read_pos == 16)
           read_struct.read_pos = 0;
    }
    if (read_struct.read_count == 0) {
        set(regs.uartFR, 0x10);    // set RXFE
    }
    if (read_struct.read_count == read_struct.read_trigger - 1) {
        clr(regs.uartRIS, 0x10); // clear RXRIS
    }
    uart_update();
    data = c;

}

void
pl011_uart::uartDR_bus_write(
        uint32_t& data,
        sc_core::sc_time& delay)
{
    set(regs.uartRIS, 0x20); // set TXRIS

    if (tx.num_free() == 0) {
      std::cout << sc_core::sc_time_stamp() << ": " << name()
           << ": terminal's receive fifo is full, character "
           << "write from uart will now block; consider increasing the size "
           << "of the terminal fifo" << std::endl;
    }
    tx.write(data);          // Send char to terminal
    uart_update();
}

uint32_t
pl011_uart::busRead(uint32_t uaddr)
{
    uint32_t data = 0;
    sc_core::sc_time delay;

    switch(uaddr) 
    {
        case DR:
            uartDR_bus_read(data, delay);
            break;
        case RSR_ECR:
            //data = regs.uartRSR_ECR;
            data = 0;
            break;
        case FR:
            data = regs.uartFR;
            break;
        case ILPR:
            data = regs.uartILPR;
            break;
        case IBRD:
            data = regs.uartIBRD;
            break;
        case FBRD:
            data = regs.uartFBRD;
            break;
        case LCR_H:
            data = regs.uartLCR_H;
            break;
        case CR:
            data = regs.uartCR;
            break;
        case IFLS:
            data = regs.uartIFLS;
            break;
        case IMSC:
            data = regs.uartIMSC;
            break;
        case RIS:
            data = regs.uartRIS;
            break;
        case MIS:
            data = regs.uartRIS & regs.uartIMSC;
            break;
        case ICR:
            data = regs.uartICR;
            break;
        case DMACR:
            data = regs.uartDMACR;
            break;
        case ID0:
            data = regs.uartID0;
            break;
        case ID1:
            data = regs.uartID1;
            break;
        case ID2:
            data = regs.uartID2;
            break;
        case ID3:
            data = regs.uartID3;
            break;
        case ID4:
            data = regs.uartID4;
            break;
        case ID5:
            data = regs.uartID5;
            break;
        case ID6:
            data = regs.uartID6;
            break;
        case ID7:
            data = regs.uartID7;
            break;
    }
  
    return (data);
}

void
pl011_uart::busWrite(uint32_t uaddr, uint32_t wdata)
{
    sc_core::sc_time delay;

    switch (uaddr) 
    {
        case DR:
            regs.uartDR = wdata;
            uartDR_bus_write(wdata, delay);
            break;
        case RSR_ECR:
            regs.uartRSR_ECR = wdata;
            break;
        case FR:
            regs.uartFR = wdata;
            break;
        case ILPR:
            regs.uartILPR = wdata;
            break;
        case IBRD:
            regs.uartIBRD = wdata;
            break;
        case FBRD:
            regs.uartFBRD = wdata;
            break;
        case LCR_H:
            regs.uartLCR_H = wdata;
            break;
        case CR:
            regs.uartCR = wdata;
            break;
        case IFLS:
            regs.uartIFLS = wdata;
            break;
        case IMSC:
            regs.uartIMSC = wdata;
            uart_update();
            break;
        case RIS:
            regs.uartRIS = wdata;
            break;
        case MIS:
            regs.uartMIS = wdata;
            break;
        case ICR:
            regs.uartRIS &= ~wdata;
            uart_update();
            break;
        case DMACR:
            regs.uartDMACR = wdata;
            break;
        case ID7:
            sc_stop();
            break;

    }
}

unsigned int
#ifdef MP_SOCKET
pl011_uart::transport_dbg(int tag, tlm::tlm_generic_payload& gp)
#else
pl011_uart::transport_dbg(tlm::tlm_generic_payload& gp)
#endif
{

    sc_dt::uint64      addr    = gp.get_address();
    uint32_t          *dataPtr;
    unsigned int      len = gp.get_data_length();

    int             offset;
    uint32_t        uaddr; 

    uaddr = (uint32_t) addr;
    offset = 0;

    dataPtr = reinterpret_cast<uint32_t*>(gp.get_data_ptr());

    switch (gp.get_command()) 
    {
        case tlm::TLM_READ_COMMAND:
             dataPtr[offset] = busRead(uaddr);
             break;
        case tlm::TLM_WRITE_COMMAND:
             busWrite(uaddr, dataPtr[offset]);
             break;
        case tlm::TLM_IGNORE_COMMAND:
            gp.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
            return (0);
    }

    gp.set_response_status(tlm::TLM_OK_RESPONSE);

    return (len);
}


void
pl011_uart::set(uint32_t &reg, uint32_t flags)
{
    reg |= flags;
}

void
pl011_uart::clr(uint32_t &reg, uint32_t flags)
{
    reg &= ~flags;
}

bool
pl011_uart::isSet(uint32_t reg, uint32_t flags)
{
    return  flags == (reg & flags);
}

bool
pl011_uart::isClr(uint32_t reg, uint32_t flags)
{
    return  flags != (reg & flags);
}


