/*
** Copyright (c) 2019 Arm Limited. All rights reserved.
*/


#ifndef SC_INCLUDE_DYNAMIC_PROCESSES
#define SC_INCLUDE_DYNAMIC_PROCESSES
#endif

#include "fterm.h"

using namespace std;

SC_HAS_PROCESS(fterm);

fterm::fterm(sc_core::sc_module_name  name, bool write_stdio_, bool write_file_) :
sc_module(name), rx("rx", 20)
{

    // Method for the Rx with static sensitivity
    SC_METHOD(writeMethod);
    sensitive << rx.data_written_event();
    dont_initialize();

    write_stdio = write_stdio_;
    write_file = write_file_;

    if (write_file) 
    {
        std::string fname(this->name());
        fname += ".log";
    
        outfile.open(fname.c_str());
    }

}


fterm::~fterm()
{
    cout << "Closing fterm" << endl;
    if (write_file)
        outfile.close();
} 


// Method handling characters on the Rx buffer
// When they arrive, write them to the file.
void
fterm::writeMethod()
{
    while (rx.num_available() != 0) {

        // read from uart
        unsigned char c = rx.read();

        if (write_stdio) cout << c;
        if (write_file) outfile << c << std::flush;
    }
}


