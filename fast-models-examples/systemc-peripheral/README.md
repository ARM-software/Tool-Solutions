## Using SystemC models with Arm Fast Models

[Arm Fast Models](https://developer.arm.com/products/system-design/fast-models) allow a subsystem from the Fast Model canvas (sgcanvas) to be exported as a SystemC component. The exported component can be connected to other SystemC models. This is a common flow for users interested in extending systems by writing peripheral models.

Multiple Fast Model subsystems can be exported and used as components in a SystemC simulation.  The exported Fast Model could be a single model or a subsystem made up of many models.  

This example demonstrates how to export a CPU and memory from the Fast Models canvas and instantiate it in SystemC along with an example SystemC peripheral model. The principles shown in this example can be extended to create any subsystem in SystemC based on Fast Models.

The design is a derivative of the examples from the [Fast Models quick start](https://github.com/ARM-software/Tool-Solutions/tree/master/hello-world_fast-models). The platform supports Windows (10) and Linux (RHEL or Ubuntu) host platforms. Two variants supplied in this package:

- An example based on Cortex-A53x1
- An example based on Cortex-M4

It may be useful to review those examples as an introduction. The example peripheral provided is a SystemC PL011 UART.

The structure of the example folder is as follows:

- Build_Cortex-A53x1 - the Cortex-A53x1 example
  - software - example software to run on the Fast Model platform 
  - system - the Fast Model platform files, including makefiles and scripts to build and clean the platform
  - run commands for Linux and Windows
- Build_Cortex-M4 - as above, but for Cortex-M4
- SystemC_Source - common SystemC source files for the platform

Start System Canvas:

Change your working directory to the system folder in the example that you want to build and run.

- For Linux: run sgcanvas from the terminal
- For Windows: open System Canvas from the Fast Models section of the Start menu

Open the example project by clicking File then Load Project and open system/systemc-peripheral-example.sgproj 

## Fast Model subsystem design

There are some differences between the sgcanvas setup for SystemC compared to the quick start examples.

Instead of compiling the hardware design into an executable, the design will be compiled into a SystemC model which can be connected to other models in SystemC.

The project settings specify to generate a SystemC component instead of a stand-alone simulator or a CADI library.

There are components and ports in the design which represent the connections that will be available in SystemC. In this case, there is a PVBus2AMBAPV bridge to a port called amba\_pv\_m. This means that a TLM connection called amba\_pv\_m will be available to connect in SystemC which represents this bus.

There is also an interrupt input which can come from SystemC and connect to the Cortex-A53 interrupt input.

The build process which compiles the SystemC main and peripheral also does the creation of the SystemC model of the components on the canvas so there is no requiremnt to use the Build button to compile the design from sgcanvas.

## SystemC design

The SystemC design (sc\_main) and an example SystemC peripheral are in the SystemC-src/ directory.

The main.cpp contains sc\_main(), the main function for the simulation. A few SystemC models make up the system. The first is the contents of the exported SystemC model. The others are regular SystemC TLM-2.0 models.

```c++
#include <scx_evs_cpu_core.h>
#include "pl011_uart.h"
#include "tterm.h"
#include "fterm.h"

```

In the sc\_main() function each model is instantiated and the ports from the sgcanvas are connected to the SystemC models. Additional bridges are used to connect between AMBA-PV TLM and generic SystemC TLM-2.0.

Instantiated components are below. The first one is the model of the canvas.

```c++
/*
 * Components
 */
scx_evs_core  cpu_core("cpu_core");
amba_pv::amba_pv_to_tlm_bridge<64> amba2tlm("amba2tlm");
pl011_uart  uart("uart");
fterm       fterm("term", true);
amba_pv::signal_from_sc_bridge<bool> sc2sig("sc2sig");
sc_signal<bool>  interrupt;
```

The ports are connected as shown here:

```c++
/*
 * Bindings
 */
    cpu_core.amba_pv_m(amba2tlm.amba_pv_s);
    amba2tlm.tlm_m.bind(uart.bus);
    uart.tx(term.rx);
    term.tx(uart.rx);
    uart.intr(interrupt);
    sc2sig.signal_in(interrupt);
    sc2sig.signal_m(cpu_core.uart_intr);
```

## Compilation

- For Linux: compile the design using the provided build\_linux.sh script. It invokes a Makefile which includes Makefile.common. The generated executable is systemc-peripheral-example.x
- For Windows: compile the deign using the provided build\_windows.cmd. It invokes the nMakefile and Visual Studio is used as the compiler. The generated executable is systemc-peripheral-example.exe The command file should be run in the VS2017 x64 Native Tools Command Prompt to ensure the proper setup of the Visual Studio compiler.

For Linux, make sure to check (and change if needed) the build\_linux.sh file to set the proper target for your gcc version.

## Cleaning

For convenience clean_linux.sh and clean_windows.cmd scripts are provided to clean up previous builds.

## Running simulation

- For Linux: run\_linux.sh 
- For Windows: run\_windows.cmd

The SystemC executable runs and loads a simple software application. In this example the UART is being modeled in SystemC. It is recommended to study the pl011\_uart.cpp and pl011\_uart.h files to see how SystemC models are created. The model shows how to use TLM-2.0 sockets for memory mapped buses and other SystemC data types for hardware modeling.

The simulation will run and automatically exit. If no 'hello world' message pops up, this may be because a terminal window is opening, printing the message, and closing automatically before it appears on the screen. Read on to the next section to select how to display the message, using models named tterm or fterm.

## Additional configuration options

The PL011 SystemC UART can be connected to a simple model which writes characters to the stdout or to file. This is done by a SystemC model named fterm and the code is in fterm.cpp and fterm.h

There is an additional option to use an interactive terminal instead of simple output to the screen or a file. This option uses xterm on Linux and telnet or putty on Windows. The alternative SystemC model is called tterm and is in the files tterm.cpp and tterm.h. This option can be uncommented in main.cpp and the fterm can be commented out. The tterm model is good for interactive applications and the fterm model is good for output only and no user interaction. In main.cpp:

```c++
// NOTE: select 1 of the 2 possible terminal models:
//       refer to the source code for the parameter values
// Uncomment the tterm model for a full terminal with xterm or telnet
tterm       term("term", true);
// Uncomment the fterm for simple file I/O (no input)
// fterm       term("term", true, false);
```

For Windows make sure telnet.exe or putty.exe is installed. There is an option to select which one is used in the tterm.cpp model source code. When using tterm be aware that the window displaying the hello message may not appear when the start and automatic exit of the application occur very close to each other.

## Simulation exit

The design demonstrates another use of SystemC modeling. In the PL011 SystemC model in the file pl011.cpp there is a check for writes to the ID7 register which is normally a read-only register. When software writes this register the model calls sc_stop() to end the simulation. This gives the software application the ability to end the simulation when the software is complete.

The software application main.c shows how to create a pointer to a hardware register and to trigger the exit by writing the hardware register:

```c
unsigned char *sim_exit = (unsigned char *) 0x1c090ffc;

// Comment out this line to see the messages in the terminal
// and manually exit using Ctrl-C
printf("\nWriting to peripheral to exit SystemC simulation\n");
*sim_exit = 0xff;
```

Be careful using the tterm model with the write to sim\_exit as the terminal will start and quickly terminate and the printf() messages will not be visible.

## Conclusion

This example shows how a Fast Model system can be extended using SystemC modeling. It is suitable for software development of all types and good for users who want to add their own SystemC TLM-2.0 models to existing Arm IP models such as the Cortex-A53 or Cortex-M4. Any third-party IP models which are available can be added in the same way. The simulation executable can be provided to software engineers for easy to use software development.
 
