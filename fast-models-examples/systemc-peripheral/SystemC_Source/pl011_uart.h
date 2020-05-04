/*
** Copyright (c) 2019 Arm Limited. All rights reserved.
*/

#ifndef PL011_UART_H
#define PL011_UART_H

//
// PL011 UART Model
//

#include <iostream>
#ifdef _WIN32
  typedef unsigned __int32 uint32_t;
#else
  #include <stdint.h>
#endif

#ifndef SC_INCLUDE_DYNAMIC_PROCESSES
#define SC_INCLUDE_DYNAMIC_PROCESSES
#endif

#include "systemc.h"
#include "tlm.h"

#ifdef MP_SOCKET
#include "tlm_utils/multi_passthrough_target_socket.h"
#else
#include "tlm_utils/simple_target_socket.h"
#endif

#define UART_ADDR_MASK 0xFFF

#define DR        0x000
#define RSR_ECR   0x004
#define FR        0x018
#define ILPR      0x020
#define IBRD      0x024
#define FBRD      0x028
#define LCR_H     0x02C
#define CR        0x030
#define IFLS      0x034
#define IMSC      0x038
#define RIS       0x03C
#define MIS       0x040
#define ICR       0x044
#define DMACR     0x048
#define ID0       0x0fe0
#define ID1       0x0fe4
#define ID2       0x0fe8
#define ID3       0x0fec
#define ID4       0x0ff0
#define ID5       0x0ff4
#define ID6       0x0ff8
#define ID7       0x0ffc


//-----------------------------------------------------------------
// fifo for uart data register
//-----------------------------------------------------------------
typedef struct  {
    unsigned read_fifo[16];
    int read_pos;
    int read_count;
    int read_trigger;
} pl011_read_struct;


class pl011_uart
  : public sc_core::sc_module
{
public:

  pl011_uart(sc_core::sc_module_name  name);

  // Simple target convenience socket for UART bus access to registers
#ifdef MP_SOCKET
  tlm_utils::multi_passthrough_target_socket<pl011_uart, 64, tlm::tlm_base_protocol_types, 1, sc_core::SC_ONE_OR_MORE_BOUND>  bus;
#else
  tlm_utils::simple_target_socket<pl011_uart, 64>  bus;
#endif

  // debug function
#ifdef MP_SOCKET
  unsigned int transport_dbg(int tag, tlm::tlm_generic_payload& gp);
#else
  unsigned int transport_dbg(tlm::tlm_generic_payload& gp);
#endif

  sc_core::sc_buffer<unsigned char>        rx;	 // Buffer for Rx in

  sc_core::sc_fifo_out<unsigned char>      tx;	 // Port to terminal for Tx

  sc_core::sc_out<bool>                    intr; // interrupt signal


public:


  // Blocking transport function. Split out separate read and write
  // functions. The busReadWrite() and busWrite() functions will be
  // reimplemented in derived classes, so are declared virtual. The
  // busRead() function is only used here, so declared private (below).
#ifdef MP_SOCKET
  virtual void   busReadWrite(int tag, tlm::tlm_generic_payload &payload,
			               sc_core::sc_time         &delay);
#else
  virtual void   busReadWrite(tlm::tlm_generic_payload &payload,
			      sc_core::sc_time         &delay);
#endif

  virtual void   busWrite(uint32_t  uaddr, uint32_t wdata);
			  

  // Flag handling utilities. Also reused in later derived classes.
  void  set(uint32_t &reg, uint32_t flag);
  void  clr(uint32_t &reg, uint32_t flag);
  bool  isSet(uint32_t reg, uint32_t flag);
  bool  isClr(uint32_t reg, uint32_t flag);
	       
  sc_core::sc_event  txReceived;

  // PL011 Registers
  struct {
     uint32_t uartDR;      // 0x000;
     uint32_t uartRSR_ECR; // 0x004;
     uint32_t uartFR;      // 0x018;
     uint32_t uartILPR;    // 0x020;
     uint32_t uartIBRD;    // 0x024;
     uint32_t uartFBRD;    // 0x028;
     uint32_t uartLCR_H;   // 0x02C;
     uint32_t uartCR;      // 0x030;
     uint32_t uartIFLS;    // 0x034;
     uint32_t uartIMSC;    // 0x038;
     uint32_t uartRIS;     // 0x03C;
     uint32_t uartMIS;     // 0x040;
     uint32_t uartICR;     // 0x044;
     uint32_t uartDMACR;   // 0x048;
     uint32_t uartID0;     // 0x0fe0;
     uint32_t uartID1;     // 0x0fe4;
     uint32_t uartID2;     // 0x0fe8;
     uint32_t uartID3;     // 0x0fec;
     uint32_t uartID4;     // 0x0ff0;
     uint32_t uartID5;     // 0x0ff4;
     uint32_t uartID6;     // 0x0ff8;
     uint32_t uartID7;     // 0x0ffc;
  } regs;


private:

    // queue for managing interrupts
    sc_core::sc_fifo<bool> intrQueue;

    pl011_read_struct        read_struct;

    // A thread to run interaction with the bus side of the UART. 
    void uart_update();

    // The method to listen to the terminal side is only used in this class and
    // never reimplemented.
    void  rxMethod();

    // thread and queue for managing interrupts
    void intrThread();

    uint32_t busRead(uint32_t uaddr);

    void uartDR_bus_read(
        uint32_t& data,
        sc_core::sc_time& delay);

    void uartDR_bus_write(
        uint32_t& data,
        sc_core::sc_time& delay);

};


#endif
