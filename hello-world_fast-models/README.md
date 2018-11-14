**Arm Fast Models quick start**

[Arm Fast Models](https://developer.arm.com/products/system-design/fast-models) are fast, flexible programmer&#39;s view models of Arm IP. Fast Models are used to build virtual prototypes for software development which are useful during all phases of a project. System models can start very small and grow into comprehensive models of hardware. Fast Models are also a great way to learn the details of software development for the Arm architecture.

Ease of use and flexibility make Fast Models an important tool for software developers. Virtual prototype creators construct system models and provide them to software developers to enable early software development.

This quick start covers how to run an example system with a minimal hello world software.

Fast Models are supported on both Linux and Windows.

**Arm developer account**

The first step is to create an account on [Arm Developer](https://developer.arm.com/). This is needed for downloads and license creation. Find the User Menu on the top right-hand corner of the page and click register. Follow the registration process and make note of your login credentials.

**Product License**

Fast Models use [FlexNet Licensing](https://www.flexera.com/products/software-monetization/flexnet-licensing.html) and the required software is not included in the Fast Model installation. Many companies have a common license server which hosts licenses for multiple products. It&#39;s worth asking to find out if there is a license server and a license administrator to find out if licenses are already available or new licenses can be added to the common server. If a server exists but doesn&#39;t have Fast Model licenses, ask for the hostid of the server.

If you need a license please e-mail [support-esl@arm.com](mailto:support-esl@arm.com) and request a 30 day trial license for Fast Models and specify which Arm CPU models you would like to try. The response will be a Serial Number which allows you to create your own license by following the steps below.

To get started with license setup, use your Arm Developer account to download the [FlexNet software](https://silver.arm.com/browse/BX002) for one of the many supported platforms.

Extract the download using tar on Linux or a program for extracting zip files on Windows.

On the machine where you want to host the license run the lmhostid command:

- For Linux: ./lmutil lmhostid
- For Windows: lmutil.exe lmhostid

Make a note of the hostid printed by lmhostid. For more information there is a pdf file with additional documentation included in the FlexNet software download.

Floating licenses can be run on any machine on the network and the license are checked out from the license server. Node locked licenses are used on the same machine running the Fast Models. Most Fast Model licenses are floating licenses and the details here are for floating licenses.

To generate a license file visit [software licensing](https://developer.arm.com/support/licensing). This area allows license files to be generated, previous license files to be viewed and retrieved, as well as other operations such as merging multiple files or moving licenses to a different server. All activity is connected to the individual Arm Developer account.

Use the Generate button and enter a serial number and hostid and a license file will be generated. Download the license file to the machine where the license server will be run. A common name for the file is license.dat but any file name can be used.

Before starting the license server, edit the license file and in the SERVER line replace _thishost_ with the hostname of the machine.

- For Linux: run uname -a
- For Windows:  visit the System area in the Control Panel and find the Computer Name

The last number on the _SERVER_ line is the port number. Make note of the port number for use during the Fast Model installation.

The license server can now be started.

- For Linux: ./lmgrd -c license.dat
- For Windows:  lmgrd.exe -c license.dat

To learn more about licensing visit the [FAQ](https://developer.arm.com/support/licensing/faq).

**Download and Install Fast Models for Windows or Linux**

Fast Models can be downloaded from the [Fast Models page on Arm Developer](https://developer.arm.com/products/system-design/fast-models). The _Evaluate_ buttons for Linux and Windows lead to the downloads. These are the complete Fast Models product, there is no functional difference implied by the evaluation label.

Extract the downloads using tar on Linux or a program for extracting zip files on Windows such as 7-Zip. Run the setup.sh on Linux or Setup.exe on Windows. In the download there is an Installation\_Guide.txt with information covering machine, OS, and compiler requirements.

During the installation a dialog will prompt for the installation location and the location of the license file. For the location of the license file enter the port@host of the FlexNet server. The port number is from the _SERVER_ line of the license file and the host is either the IP address or the machine name of the computer running the lmgrd. For example, 7010@localhost is for the current computer using port 7010.

Upon completion, the Linux installer will print how to setup the shell environment for Fast Models, with slight differences depending on the installation path.

To set up use . &quot;/home/user/ARM/FastModelsTools\_11.4/source\_all.sh&quot; for sh/ksh

To set up use source &quot;/home/user/ARM/FastModelsTools\_11.4/source\_all.csh&quot; for csh

There is no additional setup required for Windows because the environment variables are set automatically.

Environment variables can also be used to set the license file if it was not specified during installation. The variable ARMLMD\_LICENSE\_FILE can be used for all Arm products and the variable LM\_LICENSE\_FILE can be used for all products using FlexNet. Using ARMLMD\_LICENSE\_FILE is recommended for Arm products. These environment variables can be set using export (bash), setenv (csh), or in the Windows environment variables dialog.

Windows users must have Microsoft Visual Studio 2015 installed. Without this compiler it&#39;s not possible to compile and run Fast Model systems.

Linux users should have the GNU Compiler Collection installed. Supported g++ versions are 4.9, 5.4 and 6.4 but there is general compatibility across major versions.

A faster CPU and more memory will generally achieve better simulation performance, but the examples are very small and can fine on any recent computer.

**Run an example system and hello world software**

To verify the installation and license setup is correct, it&#39;s useful to run a hello world example.

Download the Fast Models hello world examples from the Arm Developer Solutions Repository at https://github.com/ARM-software/Tool-Solutions

Use git from the command line or use another git client:

git clone https://github.com/ARM-software/Tool-Solutions.git

Examples systems are provided for Cortex-M, Cortex-R, and Cortex-A. Navigate to the system/ directory of an example to get started.

Start System Canvas:

- For Linux: run sgcanvas from the terminal
- For Windows: open System Canvas from the ARM section of the Start menu

Open the example project using File -> Load Project and navigate to the .sgproj file for the Cortex-M, Cortex-R, or Cortex-A example.

Make sure &quot;Select Active Project Configuration&quot; pull down has the correct operating system and compiler.

Click the Build button to compile the system. The resulting executable is in a directory which is operating system and compiler specific and based on the selected project configuration. In the configuration subdirectory look for isim\_system on Linux ad isim\_system.exe on Windows.

Use a Linux terminal or Windows Command Prompt to run a command line simulation by passing the hello world software to the simulation:

- For Linux: isim\_system -a ../software/hello.axf
- For Windows:  isim\_system.exe -a ../software/hello.axf

The included run_windows.cmd and run_linux.sh scripts are included to automatically run the simulation using the above syntax. Either method will work.

The model for the PL011 UART will display the output and the hello world message will appear. Press Ctrl-C to exit the simulation.

To use a debugger to control the hello world software start the simulation again with -S to enable connection from a debugger which supports CADI. The simulation will wait for a debugger to connect before starting execution.

- For Linux: isim\_system -a ../software/hello.axf -S
- For Windows:  isim\_system.exe -a ../software/hello.axf -S

Any debugger with CADI support can be used to connect, control the software execution, and inspect the CPU and software.

Arm debuggers with CADI support are:

- [Model Debugger](https://developer.arm.com/docs/100968/1101/introduction/about-model-debugger)
- [Arm DS-5](https://developer.arm.com/products/software-development-tools/ds-5-development-studio) 
- [uVision](http://www2.keil.com/mdk5/uvision/)


Model Debugger is included in Fast Models. To start it:

- For Linux, run modeldebugger from the terminal
- For Windows, open Model Debugger from the Arm section of the Start menu

Use the File -> Connect to Model menu item to open a dialog box which selects the running simulation to connect to. Click OK and select the hello.axf when prompted. Use the debugger controls to step, run, and examine instructions, registers, and memory.

It&#39;s possible for System Canvas to launch the simulation directly and connect Model Debugger. Refer to the [Fast Models User Guide](https://developer.arm.com/products/system-design/fast-models/docs/100965/latest/system-canvas-tutorial/debugging-with-model-debugger) for more information.

Depending on the licenses available, select the correct example for the Cortex-M, Cortex-R, or Cortex-A core. If a license for the default CPU is not available, the system can be changed to use a similar CPU which is available. Because the simple hello world program assumes very little about the underlying hardware or use any special hardware features, the following cores can be substituted in their category:
- Cortex-A_Armv7-A
	- Cortex-A5 		
	- Cortex-A7 		
	- Cortex-A8 		
	- Cortex-A9 		
	- Cortex-A15 		
	- Cortex-A17 		
	- Cortex-A32          *This core uses Armv8-A but works here as the Armv8-A code assumes 64-bit compatibility.
- Cortex-A_Armv8-A
	- Cortex-A35 		
	- Cortex-A53   		
	- Cortex-A55 		
	- Cortex-A57 		 
	- Cortex-A72 		 
	- Cortex-A73		
	- Cortex-A75 		
- Cortex-M
	- Cortex-M0	 	
	- Cortex-M0+		
	- Cortex-M3 		
	- Cortex-M4 		
	- Cortex-M7 		
	- Cortex-M23		
	- Cortex-M33 		
- Cortex-R_Armv7-R
	- Cortex-R4 		
	- Cortex-R5 			
	- Cortex-R7 		
	- Cortex-R8 		
- Cortex-R_Armv8-R
	- Cortex-R52		

To replace CPUs, drag the desired core from the component list onto the canvas. Connect the new core to the same ports as the initial core, delete the initial core, and recompile the model. Refer to the [System Canvas Tutorial](https://developer.arm.com/products/system-design/fast-models/docs/100965/latest/system-canvas-tutorial) for more information.

This quick start explained how to get up and running with Arm Fast Models. Please e-mail [support-esl@arm.com](mailto:support-esl@arm.com) or visit [Arm Support](https://developer.arm.com/support/) to open a support case. For any questions or comments about the Arm Developer Solutions Repository and this example e-mail [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com)
