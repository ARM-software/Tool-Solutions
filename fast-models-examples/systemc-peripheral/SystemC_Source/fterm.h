/*
** Copyright (c) 2019 Arm Limited. All rights reserved.
*/

#ifndef FTERM__H
#define FTERM__H

#include "systemc.h"

#include <iostream>
#include <fstream>
#include <sys/types.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>


class fterm
: public sc_core::sc_module {
public:

    fterm(sc_core::sc_module_name name, bool write_stdio_, bool write_file_);
    ~fterm();

    // Buffer for input to the terminal and port to connect to the UART buffer
    // for output
    sc_core::sc_fifo<unsigned char>  rx;      // Buffer for Rx in
    sc_core::sc_out<unsigned char>   tx;      // Port to UART for Tx

protected:

private:

    void      writeMethod();
    bool      write_stdio;
    bool      write_file;
    ofstream  outfile;

};

#endif	// FTERM__H
