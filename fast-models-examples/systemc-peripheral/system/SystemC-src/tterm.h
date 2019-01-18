/*
** Copyright (c) 2019 Arm Limited. All rights reserved.
*/


#ifndef TTERM__H
#define TTERM__H

#include "systemc.h"

#include <iostream>
#include <sys/types.h>
#include <fcntl.h>


#ifdef _WIN32
#include <winsock2.h>
typedef unsigned __int32 ssize_t;
#else
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#endif

#include <signal.h>
#include <errno.h>
#include <string>
#include <iostream>
#include <sstream>


class tterm
: public sc_core::sc_module {
public:

    tterm(sc_core::sc_module_name name, bool telnet_);
    ~tterm();

    // Buffer for input to the terminal and port to connect to the UART buffer
    // for output
    sc_core::sc_fifo<unsigned char>  rx;      // Buffer for Rx in
    sc_core::sc_out<unsigned char>   tx;      // Port to UART for Tx

protected:

    virtual void  readThread();

    int socketRead(unsigned char *data_char);


private:
    int startConnection(bool start_telnet);

    void  writeMethod();

    void socketWrite( unsigned char  ch );

    bool            connected;
    bool            telnet;
    struct          timeval timeVal;
    int             socSocket;
    int             socClient;


    FILE *rxt;
    char lxt[256];
    struct sockaddr_in    saClient;
#ifdef _WIN32
    int       saClientLen;
#else
    socklen_t saClientLen;
#endif

    sc_event  startReading;


};

#endif	// TTERM__H
