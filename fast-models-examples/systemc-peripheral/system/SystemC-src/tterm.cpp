/*
** Copyright (c) 2019 Arm Limited. All rights reserved.
*/

#ifndef SC_INCLUDE_DYNAMIC_PROCESSES
#define SC_INCLUDE_DYNAMIC_PROCESSES
#endif

#include "tterm.h"

using namespace std;

SC_HAS_PROCESS(tterm);

#define INPUT_POLL_TIME_INTERVAL 10
#define INPUT_POLL_TIME_UNIT     SC_US

#define	PORT_NUM	((unsigned short) 1234)

#ifndef MAXHOSTNAMELEN
    #define MAXHOSTNAMELEN	512
#endif

tterm::tterm(sc_core::sc_module_name  name, bool telnet_) :
sc_module(name), rx("rx", 20)
{

    // Method for the Rx with static sensitivity
    SC_METHOD(writeMethod);
    sensitive << rx.data_written_event();
    dont_initialize();

    // Thread for the xterm
    SC_THREAD(readThread);

    telnet = telnet_;

    connected = false;
    timeVal.tv_sec = 0;
    timeVal.tv_usec = 0;
    socSocket = -1;
    socClient = -1;
}


tterm::~tterm()
{
    cout << "Closing connection" << endl;
#ifdef _WIN32
    closesocket(socClient);
    closesocket(socSocket);
#else
    close(socClient);
    close(socSocket);
#endif
} 


// Method handling characters on the Rx buffer
// When they arrive, write them to the socket.
void
tterm::writeMethod()
{
    startReading.notify();

    while (rx.num_available() != 0) {

        // read from uart
        unsigned char c = rx.read();

        // write to network socket
        socketWrite(c);
    }
}


// Thread listening for characters from the network socket.
// At startup, Wait to be notified via a SystemC event that the 
// first write to the UART has occurred.
// Read the character from the socket, then send it out to the UART.
void
tterm::readThread()
{
    unsigned char c;
    int           st;

    while (true) {

        // this will cause the terminal to delay opening until the first write by software
        //wait(startReading);

        if (!startConnection(telnet))
            return;

        while (connected == true) {

            wait(INPUT_POLL_TIME_INTERVAL, INPUT_POLL_TIME_UNIT);

            st = socketRead(&c);
            if (st)  {
                tx.write(c);
            }
        }
    }
}

int
tterm::startConnection(bool start_telnet)
{
    char        hostname[MAXHOSTNAMELEN + 1];
    int         st;
    ssize_t     size;
    char        banner[] = "Connected to SystemC virtual UART\r\n";
    int         retryCount = 0;
    unsigned short    incr = 0;
    struct sockaddr_in    saMe;

    
#ifdef _WIN32
    // Initialize Winsock
    int iResult;
    WSADATA wsaData;
    iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
    if (iResult != 0) {
        std::cout << "WSAStartup failed: " << iResult << std::endl;
        return 0;
    }
#endif
    
    if (connected == false) {
        // Create socket
#ifdef _WIN32
        if ((socSocket = socket(PF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) {
            printf("Could not create socket: %d", WSAGetLastError());
            return 0;
        }
#else        
        if ((socSocket = socket(PF_INET, SOCK_STREAM, 0)) < 0) {
            perror("socket()");
            return 0;
        }
#endif

        // Get my host name
        if ((gethostname(hostname, MAXHOSTNAMELEN)) < 0) {
            perror("gethostname()");
            return 0;
        }

        // Bind address and port number to the socket
        while (retryCount < 5) {
            memset(&saMe, 0, sizeof(saMe));
            saMe.sin_family = AF_INET;  
            saMe.sin_addr.s_addr = htonl(INADDR_ANY);
            saMe.sin_port = htons(PORT_NUM+incr);
            st = ::bind(socSocket, (struct sockaddr *)&saMe, sizeof(saMe));
            if (st >= 0)
                break;

            ++incr;
            ++retryCount;
            cout << "Retrying..." << endl;
#ifdef _WIN32
            Sleep(5);
#else
            sleep(5);
#endif
        }

        if (st < 0) {
            perror("bind() failed");
            return 0;
        }

        // Allocate socket buffer
        if ((listen(socSocket, 5)) < 0) {
            perror("listen()");
            return 0;
        }

        // Wait for connection
        cout << "Connected to port: " << PORT_NUM+incr << endl;

        if (start_telnet) {
            char xt[128];
#ifdef _WIN32
            std::ostringstream cmd;
            cmd << getenv("SystemRoot") << "\\system32\\cmd.exe";
            sprintf(xt, "/c telnet.exe localhost %d", PORT_NUM+incr);
            //sprintf(xt, "/c putty.exe -raw localhost %d", PORT_NUM+incr);
            STARTUPINFO si;
            PROCESS_INFORMATION pi;
            memset(&si, 0, sizeof(STARTUPINFO));
            si.cb = 0;
            char *args = strdup(xt);
			
            CreateProcess(cmd.str().c_str(),
                             args,
                             NULL,
                             NULL,
                             false,
                             CREATE_NEW_CONSOLE,
                             NULL,
                             NULL,
                             &si,
                             &pi);
							 
#else
            
            sprintf(xt, "xterm -sb -e telnet %s %d 2>&1", hostname, PORT_NUM+incr);
            cout << "Auto start of UART terminal using '" << xt << "' ..." << endl;
            rxt = (FILE*)popen((const char*) xt, "r");            
            int fd = fileno(rxt);
            int flags = fcntl(fd, F_GETFL, 0);
            flags |= O_NONBLOCK;
            fcntl(fd, F_SETFL, flags);

            while (fgets(lxt,sizeof(lxt),rxt)) {
                cout << "UART_INFO: " << lxt;
            }

            if (!rxt) {
                cout << "Auto-start of UART terminal failed, check xterm PATH or DISPLAY environment" << endl;
                cout << "Reverting to manual start ..." << endl;
                if (rxt) pclose(rxt);		
                rxt=NULL;
            }
#endif
        }

        retryCount = 0;
        while (retryCount < 5) {
            saClientLen = sizeof(saClient);
			memset(&saClient, 0, sizeof(saClient));
            socClient = accept(socSocket, (struct sockaddr *)&saClient, &saClientLen);
            if (socClient >= 0)
                break;
            if (errno != EINTR) {
                perror("accept()");
                cout << "Retrying..." << endl;
            }
            ++retryCount;
#ifdef _WIN32
            Sleep(1);
#else
            sleep(1);
#endif
        }

        if (socClient < 0) {
            perror("accept() failed");
            return 0;
        }

        cout << "Client connected." << endl;

        // Ignore SIGPIPE for write()
        //signal(SIGPIPE, SIG_IGN);

        connected = 1;

        if (start_telnet) {

            size = send(socClient, banner, sizeof(banner) - 1, 0);

            if (size < 0) {
                perror("write()");
                connected = 0;
            }
        }
    }
    return(connected);
}


int
tterm::socketRead(unsigned char *data_char)
{
    fd_set      fdSet;
    int     status;
    ssize_t     size;
    char        readBuf[1024];

    FD_ZERO(&fdSet);
    FD_SET(socClient, &fdSet);
    // if select returns EINTR try again
    while ((status = select(socClient + 1, &fdSet, NULL, NULL, &timeVal)) <0 && errno == EINTR);
    if (status < 0) {
        perror("select() on read");
        connected = false;
        return 0;
    }

    if (status > 0 && FD_ISSET(socClient, &fdSet)) {
        size = recv(socClient, readBuf, 1, 0);

        if (size == 0) {
            cout << "Connection Closed" << endl;
#ifdef _WIN32
            closesocket(socClient);
            closesocket(socSocket);
#else
            close(socClient);
            close(socSocket);
#endif
            connected = false;
            return 0;
        }
        else if (size < 0) {
            connected = false;
            return 0;
        }

        *data_char = readBuf[0];
        return 1;

    }
    return 0;
}


void
tterm::socketWrite(unsigned char  ch)
{
    ssize_t     size;

    if (connected && socClient >= 0) {

        size = send(socClient, (const char *) &ch, 1, 0);

        if (size < 0) {
            perror("write()");
            connected = 0;
        }

        if(ch == 0xa)
        {
            // CR needs to be inserted for every newline
            ch=0xd;
            size = send(socClient, (const char *) &ch, 1, 0);
        }

    }

}
