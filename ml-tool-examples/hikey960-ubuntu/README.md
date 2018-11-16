## Run Ubuntu Linux on the HiKey 960

The [HiKey 960 board](http://www.96boards.org/product/hikey960/) with a [HiSilicon Hi3660 SoC](https://github.com/96boards/documentation/blob/master/consumer/hikey/hikey960/hardware-docs/HiKey960_SoC_Reference_Manual.pdf) is a great development board with good performance and recent Arm IP. It runs the latest [Android Pie](https://www.android.com/versions/pie-9-0/), and contains the [Cortex-A73](https://developer.arm.com/products/processors/cortex-a/cortex-a73), [Cortex-A53](https://developer.arm.com/products/processors/cortex-a/cortex-a53), and [Mali-G71](https://developer.arm.com/products/graphics-and-multimedia/mali-gpus/mali-g71-gpu) IP from Arm. The HiKey 960 is affordable and is fully supported by the [Android AOSP](https://source.android.com/source/devices#hikey960) (Android Open Source Project). The HiKey is also great for Linux development, but the details on how to install Linux are more difficult compared to Android. The info below explains one way to install Ubuntu Linux on the HiKey 960.

Besides the board, gather up the required hardware. An HDMI monitor and cable, USB keyboard, USB type-C to USB cable (to connect the HiKey to your computer), and power supply are needed. Additionally, a good way to move the small switches on the board of the board needed. This can be a small nail or paper clip.

Let&#39;s get started with the information to install Ubuntu Linux on the Hikey 960. The recipe uses a Ubuntu 18.04 host machine, but the instructions should be similar for other Linux distributions. Even though some of the steps will work, Windows is not recommended as a host machine.  The general steps are:

* Run a recovery to make sure the parition table is correct
* Flash firmware and Linux operating system
* Boot and run Linux 

## Building Ubuntu filesystem

Before doing any board flashing an Ubuntu root filesystem is needed. The root filesystem for a Linux distribution is large and not easy to distribute as a binary file. It can be created from scratch, and having the ability to create it means it can be customized and used to flash multiple boards. This walk-through builds the Linux distribution from scratch using the build.sh script in the build-ubuntu/ directory.

To build the root filesystem change directory to the build-ubuntu/ directory and run the build.sh script. This file has a script to build the filesystem and some extra artifacts that need to be placed into the filesystem. For customization study the files build.sh and config-fs.sh

The script will ask for the sudo password on the host machine 1 or 2 times so enter it when needed.

```console
$ cd build-ubuntu/
$ ./build.sh
```

It will take some time to download the packages for the Armv8-A version of Ubuntu. If all goes well, the result is the output file ubuntu/system.simg  This file represents the root filesystem that can be flashed to the HiKey 960 system partition. It will be used in a later step.

## Flashing the base firmware and OS

The flash process builds on an [existing proejct used to flash the base firmware and operating system](https://github.com/96boards-hikey/tools-images-hikey960). It also ensures the partion table is reset to the default state before installing the operating system. The flow is to clone the project from github, copy in some new files, and run the flash procedure.

```console
$ git clone https://github.com/96boards-hikey/tools-images-hikey960
```
The [Fastboot](http://manpages.ubuntu.com/manpages/xenial/man1/fastboot.1.html) utility is used to flash the images. It can be obtained either from the [Android SDK platform tools](https://developer.android.com/studio/releases/platform-tools) or installed using:
```console
$ sudo apt-get install fastboot
```
Flashing the base firmware may or may not be required depending on the state of your board, but I recommend to do it anyway for best results. To flash the base firmware follow the procedure from [96boards.org](https://www.96boards.org/documentation/consumer/hikey/hikey960/installation/board-recovery.md.html), which is outlined below.

Break the process into two parts, recovery mode and fastsboot mode, as described below. First, get familiar with the switches on the board. All three modes are going to be used.

The board has three distinct modes: normal, fastboot, and recovery. All modes are controlled by the switches on the back.


| **Name** | **Link / Switch** | **Normal Mode** | **Fast boot Mode** | **Recovery Mode** |
| --- | --- | --- | --- | --- |
| **Auto Power up** | Link 1-2 / Switch 1 | closed / ON | closed / ON | closed / ON |
| **Recovery** | Link 3-4 / Switch 2 | open / OFF | open / OFF | closed / ON |
| **Fastboot** | Link 5-6 / Switch 3 | open / OFF | closed / ON | open / OFF |

### Recovery mode

First put the board in recovery mode by setting the switches correctly using the above table, connect the HiKey 960 board to your host machine via the USB-C (on the HiKey) to USB (host machine), and power it on. On the host machine look in /dev/ for ttyUSB0 or ttyUSB1. The device node which appears after powering on the board is the one to use in the recovery procedure.

Run the recovery procedure using the recover.sh script; this runs the hikey_idt Linux binary. Firstly copy all the files in flash-images/ to the tools-images-hikey960/ directory, then run the recover.sh script with the device node the HiKey 960 board as the argument:

```console
$ cp flash-images/* tools-images-hikey960/
$ ./recovery.sh /dev/ttyUSB0
Config name: config
Port name: /dev/ttyUSB0
0: Image: ./hisi-sec_usb_xloader.img Downalod Address: 0x20000
1: Image: ./hisi-sec_uce_boot.img Downalod Address: 0x6a908000
2: Image: ./hisi-sec_fastboot.img Downalod Address: 0x1ac00000
Serial port open successfully!
Start downloading ./hisi-sec_usb_xloader.img@0x20000...
file total size 99584
downlaod address 0x20000
Finish downloading
Start downloading ./hisi-sec_uce_boot.img@0x6a908000...
file total size 23680
downlaod address 0x6a908000
Finish downloading
Start downloading ./hisi-sec_fastboot.img@0x1ac00000...
file total size 3430400
downlaod address 0x1ac00000
Finish downloading
```

### Fastboot mode to flash the remaining images

With the HiKey 960 board now flashed with the basic boot code the next step is to flash the remaining images including the bootloader, linux kernel and file system. To do so, power off the board, move the switches to Fastboot mode, and power the board back on.

In the host machine, confirm the board is visible with fastboot.
```console
$ sudo fastboot devices
447786182000000        fastboot
```
Before the HiKey board can be flashed, the proper images and setup scripts must be in the same directory. From the last step, the script fastboot.sh and two Linux images boot.img and dts.img were copied from flash-images/ to the tools-images-hikey960/ directory. The system.simg file, generated in the first step, also needs to be copied into the tools-images-hikey960/ directory.

```console
$ cp build-ubuntu/ubuntu/system.simg tools-images-hikey960/
```
In summary, the Linux related images in the tools-images-hikey960 directory are:

- boot.img
- dts.img
- system.simg

In the tools-images-hikey960/ directory run the fastboot.sh script:
```console
$ ./fastboot.sh
```
Here is the contents of the fastboot.sh. It should flash all the images.
```console
#!/bin/bash -e

DEVICE=$1
IMG_FOLDER=${PWD}

# partition table
sudo fastboot flash ptable ${IMG_FOLDER}/hisi-ptable.img

# bootloader
sudo fastboot flash xloader ${IMG_FOLDER}/hisi-sec_xloader.img
sudo fastboot flash fastboot ${IMG_FOLDER}/hisi-fastboot.img

# extra images
sudo fastboot flash nvme   ${IMG_FOLDER}/hisi-nvme.img
sudo fastboot flash fw_lpm3   ${IMG_FOLDER}/hisi-lpm3.img
sudo fastboot flash trustfirmware   ${IMG_FOLDER}/hisi-bl31.bin

# linux kernel and file system
sudo fastboot flash boot boot.img
sudo fastboot flash dts dts.img
sudo fastboot flash system system.simg
```
## Boot Linux

Now the HiKey 960 board is ready to boot Linux. To do so, turn the board off, put the switches in normal mode, disconnect the USB type-C cable, connect an HDMI monitor via the HDMI cable and plug in a USB keyboard. There is a way to view the HiKey through a console via host computer but it requires the [96boards UART adapter](https://www.96boards.org/product/uartserial/) adapter and is not covered here. Feel free to use the UART adapter instead of an HDMI monitor.

With the HiKey 960 board connected to a monitor, power on the board. Linux should boot and come to a login prompt on the HDMI monitor. Sign in using the below credentials (The password contains ml as in machine learning, not a number 1):

username: arm01
password: armml2018

The HiKey 960 board is now successfully running Linux. To connect and control the board from another machine, connect the HiKey 960 to a wireless network and ssh into the board.

After login, run the utility nmtui and connect to a local wireless network using the &quot;Activate a Connection&quot; menu item. Select the router and enter the key to join the network.

```console
$ nmtui
```
Run the ifconfig command to get the ip the board.
```console
$ ifconfig
```
Now try to ssh to the HiKey 960 ip address from another machine using the same login/pw as above.

## Adding more diskspace

The partition with the root filesystem is only 4 Gb. If more space is required another filesystem can be created on the user partition and mounted. Adding 4 Gb of swap space is also recommended.

There is a script in the HiKey960 Linux home directory at $HOME/filesys.sh which will create another filesystem and the swap space. Read it over to understand what sections fit your needs. You can use only parts of it or just run it.
```console
$ sudo ./filesystem.sh
```
Answer yes to create a new filesystem and the swap space. The result is a new filesystem mounted on $HOME/armnn-devenv with more space and a swap file at $HOME/armnn-devenv/swapfile

For projects using a lot of diskspace do the work in $HOME/armnn-devenv to take advantage of this new space.

## Summary

Setting up Ubuntu Linux on the HiKey 960 board takes a few steps, but the provided information will jumpstart Linux software development.

