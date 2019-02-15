## Run Ubuntu Linux on the Rock 960

The [Rock 960 board](https://www.96boards.org/product/rock960/) with a [Rockchip RK3399 SoC](https://www.96boards.org/documentation/consumer/rock/rock960/hardware-docs/) is a great development board with good performance and recent Arm IP. It runs Linux and [Android](https://www.android.com/), and contains the [Cortex-A72](https://developer.arm.com/products/processors/cortex-a/cortex-a72), [Cortex-A53](https://developer.arm.com/products/processors/cortex-a/cortex-a53), and [Mali-T880](https://developer.arm.com/products/graphics-and-multimedia/mali-gpus/mali-t860-and-mali-t880-gpus) IP from Arm. 

Besides the board, gather up the required hardware. An HDMI monitor and cable, USB keyboard, and power supply are needed. 

The easiest way is to run directly from an SD card. This eliminates the need to flash the eMMC. 

## Download Linux image and write SD card

The Ubuntu 16.04 Linux image can be downloaded from the [Rock 960 downloads page](https://www.96boards.org/documentation/consumer/rock/downloads/ubuntu.md.html). Download the [single file for SD Card](https://dl.vamrs.com/products/rock960/images/ubuntu/rock960_ubuntu_server_16.04_arm64_20180115.tar.gz).
  
  For Linux, use the lsblk command to find the device node for hte SD card and then use the dd command to write the image. 
  
 ```
 $ sudo dd if=system.img of=/dev/mmcblk0 bs=4M oflag=sync status=noxfer
 ```
  
There are many ways to write the image to the SD card depending on the host operating system. The [installation page](https://www.96boards.org/documentation/consumer/rock/installation/) has various options for Windows, Linux, and Mac.
 
## Boot Linux

Insert the SD card and power on the Rock 960 to boot Linux. 

With the Rock 960 board connected to a monitor the Linux should boot and come to a login prompt. Sign in using the credentials:

username: rock
password: rock

The Rock 960 board is now successfully running Linux. To connect and control the board from another machine, connect the Rock 960 to a wireless network and ssh into the board.

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

The partition with the root filesystem will be small and does not use the entire SD card. The file system can be resized to use the entire SD card. Here is an example of how to resize the file system to use the entire SD card. 

```console
$ sudo parted /dev/mmcblk0
GNU Parted 3.2
Using /dev/mmcblk0
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print free
Model: SD SC64G (sd/mmc)
Disk /dev/mmcblk0: 63.9GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name     Flags
        17.4kB  32.8kB  15.4kB  Free Space
 1      32.8kB  4129kB  4096kB               loader1
        4129kB  8389kB  4260kB  Free Space
 2      8389kB  12.6MB  4194kB               loader2
 3      12.6MB  16.8MB  4194kB               trust
 4      16.8MB  134MB   117MB   fat16        boot     boot, esp
 5      134MB   63.9GB  63.7GB  ext4         rootfs

(parted) resizepart 5
End?  [63.9GB]?
(parted) q
$ sudo resize2fs /dev/mmcblk0p5
```
## Add swapspace

Run the script to add some swapspace. It can prevent hangs if using the Rock 960 with 2 Gb of RAM and memory gets low.
```
$ sudo ./swap.sh
```

## Install git and start development

To get going with the ML examples install git:
```console
$ sudo apt install git
```
## Summary

Setting up Ubuntu Linux on the Rock 960 board takes a few steps, but the provided information will jumpstart Linux software development.

