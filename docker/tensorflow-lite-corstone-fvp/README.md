# How to port Tensorflow Lite for Microcontroller applications to the Arm Corstone-300 FVP

This Docker project goes with an Arm Community blog, [Kickstart your ML development with free Ethos-U55 platform](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/)

The article explains how to use Arm Compiler 6 to build and run TensorFlow Lite Applications on Arm Corstone-300 FVP. It requires version 6.14 or greater for support of the Cortex-M55 processor.

Please use github to ask for help or e-mail [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com)

FlexNet licensing is used in many Arm tools. Some helpful information is below if you are new to FlexNet licensing for Arm tools.

## Arm developer account

The first step is to create an account on [Arm Developer](https://developer.arm.com/). This is needed for downloads and license creation. Find the User Menu on the top right-hand corner of the page and click register. Follow the registration process and make note of your login credentials.

## Product License

Many Arm tools use [FlexNet Licensing](https://www.flexera.com/products/software-monetization/flexnet-licensing.html) and the required software is not included in the tools installation. Many companies have a common license server which hosts licenses for multiple products. It&#39;s worth asking to find out if there is a license server and a license administrator to find out if licenses are already available or new licenses can be added to the common server. If a server exists but doesn&#39;t have the required licenses, ask for the hostid of the server.

If you need a license please e-mail [license.support@arm.com](mailto:license.support@arm.com) and request a 30 day trial license for Arm Compiler 6. The response will be a Serial Number which allows you to create your own license by following the steps below.

To get started with license setup, use your Arm Developer account to download the [FlexNet software](https://silver.arm.com/browse/BX002) for one of the many supported platforms.

Extract the download using tar on Linux or a program for extracting zip files on Windows.

On the machine where you want to host the license run the lmhostid command:

- For Linux: ./lmutil lmhostid
- For Windows: lmutil.exe lmhostid

NOTE: If you recieve the strange error of './lmutil: No such file or directory' on Linux the library 'Linux Standard Base' should be installed. To do so on Ubuntu for example type 'sudo apt-get install lsb' and try the above './lmutil lmhostid' command again.

Make a note of the hostid printed by lmhostid. For more information there is a pdf file with additional documentation included in the FlexNet software download.

Floating licenses can be run on any machine on the network and the license are checked out from the license server. Node locked licenses are used on the same machine running the compiler. Most licenses are floating licenses and the details here are for floating licenses.

To generate a license file visit [software licensing](https://developer.arm.com/support/licensing). This area allows license files to be generated, previous license files to be viewed and retrieved, as well as other operations such as merging multiple files or moving licenses to a different server. All activity is connected to the individual Arm Developer account.

Use the Generate button and enter a serial number and hostid and a license file will be generated. Download the license file to the machine where the license server will be run. A common name for the file is license.dat but any file name can be used.

Before starting the license server, edit the license file and in the SERVER line replace _thishost_ with the hostname of the machine.
- For Linux: run uname -a
- For Windows:  visit the System area in the Control Panel and find the Computer Name

The last number on the _SERVER_ line is the port number. Make note of the port number for use during tool setup. The environment variable ARMLMD_LICENSE_FILE is used to reference the port@host for license checkout.

The license server can now be started.

- For Linux: ./lmgrd -c license.dat
- For Windows:  lmgrd.exe -c license.dat

To learn more about licensing visit the [FAQ](https://developer.arm.com/support/licensing/faq).

## Detailed Steps to build the Tensorflow Lite Micro Applications and run them on Corstone-300 FVP
To get started clone the project repository from github:

	$git clone https://github.com/ARM-software/Tool-Solutions.git
	$cd Tool-Solutions/docker/tensorflow-lite-corstone-fvp

The tensorflow-lite-corstone-fvp project contains everything you need to build and run Tensorflow Lite for Microcontrollers examples on the Corstone-300 FVP. We are using a Docker-based development environment for our project. It makes it easier to create a known good development environment with all the dependencies in one package.

First, download Arm Compiler 6.15 for Linux. You can download it directly from [Arm Developer] (https://developer.arm.com/tools-and-software/embedded/arm-compiler/downloads/version-6) or by running the get-ac6.sh file:

	$./get-ac6.sh

Then, build the Docker image for this project by running the build.sh script. You can inspect the Dockerfile included in the project which contains all the commands to assemble the docker image for this project.
	
	$./build.sh

Next, start the docker container by running the run.sh script

	$./run.sh

We are now in the Docker container and can start building the TensorFlow Lite Micro example applications targeted to run on the Corstone-300 FVP

To build the example applications targeted to run on the Corstone-300 FVP use the build_tflite_micro_test.sh script in the software directory. The example use-case/application you want to build and the input image for that use-case is passed as an argument to this script. The use-cases/applications that can be built are img_class and micro_speech. To see all the available arguments/options with this script use the help option.

	$cd ~/software
	$./build_tflite_micro_app.sh -h

To build the micro_speech executable in the container use the following command:
	
	$cd ~/software
	$./build_tflite_micro_app.sh -t m55+u55 -u micro_speech

Alternatively, to build the img_class executable and use the cat image as an input, use the following commands in your running docker container:
	
	$cd ~/software
	$./build_tflite_micro_app.sh -t m55+u55 -u img_class -i cat 

The output executable (micro_speech.axf or img_class.axf) is put into the software/exe/micro_speech and software/exe/img_class directory respectively.

Now that you've built the Tensorflow Lite for Microcontrollers executables for either/both use cases (*.axf) you can run them on the Corstone-300 FVP that has already been downloaded and installed in your running docker container

First, navigate to the system directory where the FVP is installed

	$cd ~/system/FVP_Corestone_SSE-300_Ethos-U55/

Now to run micro_speech on the Corstone-300 FVP, use the following command in your running container
	
	$./run-fvp.sh -u micro_speech

To run the img_class executable, use the following command

	$./run-fvp.sh -u img_class

The output from running these executables on the FVP is displayed on the console. The classification results for both these examples are also displayed at the end of the simulation on the console. The img_class use case takes longer to run as compared to micro_speech. 


## Summary

This quick start explained how to setup a license server for Arm tools such as Arm Compiler 6. It details all the steps necessary to build and run the Tensorflow Lite for Microcontroller use-cases on the Arm Corstone-300 FVP.  Please e-mail [support-esl@arm.com](mailto:support-esl@arm.com) or visit [Arm Support](https://developer.arm.com/support/) to open a support case. For any questions or comments about the Arm Developer Solutions Repository and this example e-mail [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com)
