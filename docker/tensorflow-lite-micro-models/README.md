# How to port Tensorflow Lite for Microcontroller applications to the Arm Cortex-M55 Processor

This Docker project goes with an Arm Community blog, [How to port TensorFlow Lite for Microcontroller applications to the Arm Cortex-M55 Processor](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/port-tensorflow-lite-for-cortex-m55)

The article explains how to use Arm Compiler 6 to build and run performance analysis tests using Tensorflow Lite Applications and Arm Compiler 6. It requires version 6.14 or greater for support of the Cortex-M55 processor.

Please use github to ask for help or e-mail [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com)

FlexNet licensing is used in many Arm tools. Some helpful information is below if you are new to FlexNet licensing for Arm tools.

## Arm developer account

The first step is to create an account on [Arm Developer](https://developer.arm.com/). This is needed for downloads and license creation. Find the User Menu on the top right-hand corner of the page and click register. Follow the registration process and make note of your login credentials.

## Product License

Many Arm tools use [FlexNet Licensing](https://www.flexera.com/products/software-monetization/flexnet-licensing.html) and the required software is not included in the tools installation. Many companies have a common license server which hosts licenses for multiple products. It&#39;s worth asking to find out if there is a license server and a license administrator to find out if licenses are already available or new licenses can be added to the common server. If a server exists but doesn&#39;t have the required licenses, ask for the hostid of the server.

If you need a license please visit [Arm support](https://developer.arm.com/support) and request a 30 day trial license for Arm Compiler 6. The response will be a Serial Number which allows you to create your own license by following the steps below.

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

## Summary

This quick start explained how to setup a license server for Arm tools such as Arm Compiler 6. Please visit [Arm Support](https://developer.arm.com/support/) to open a support case. For any questions or comments about the Arm Developer Solutions Repository and this example e-mail [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com)
