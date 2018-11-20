## Arm NN build scripts
This directory contains build scripts for Arm NN.

The scripts are tested on Ubuntu 18.04 host machines and use the Ubuntu package manager to install any missing packages on the host before starting the build. Edit the script as needed for other host operating systems.

## Native build on Arm Linux systems
The build-armnn.sh script builds Arm NN and Arm Compute Library as a native build on an Arm Linux system. Example systems are [HiKey 960 running Ubuntu](https://github.com/ARM-software/Tool-Solutions/tree/master/ml-tool-examples/hikey960-ubuntu), Acer Chromebook R13 using [crouton](https://github.com/dnschneid/crouton), and Raspbery Pi 3 Running [Ubuntu MATE](https://ubuntu-mate.org/raspberry-pi). Run this script before building and running the [MNIST demo](https://github.com/ARM-software/Tool-Solutions/tree/master/ml-tool-examples/mnist-demo) and [MNIST draw](https://github.com/ARM-software/Tool-Solutions/tree/master/ml-tool-examples/mnist-draw) applications.

```bash
## Run the build
./build-armnn.sh
```
A logfile is created all of the build is done under $HOME/armnn-devenv 

Instrumented versions of Arm NN and Compute Library are used to enable Streamline profiling.


