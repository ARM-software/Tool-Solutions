# Simple multi-architecture Docker example C program
A simple C program which prints the host architecture of the running container.

It shows how to use docker buildx to create images for multiple architectures and run them.

## Requirements
To run the example make sure Docker is installed. The example is made for [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows and Mac, but also works on Linux. 

A [Docker Hub](https://hub.docker.com/) accout is also required to save images. Have your Docker ID available.

The scripts are .ps1 to run on Windows PowerShell but they run with bash as well, just put bash in front of the files.

## Usage instructions
Here are the steps to run the demo:

  1. After cloning, change directory
     - ```cd c-hello-world```
  2. Login to your Docker Hub account
     - ```docker login```
  3. Edit the build.ps1 script to use your Docker ID and run it
     - ```build.ps1```
  4. Edit the inspect.ps1 script to use your Docker ID and run it to see the multi-architecture image
     - ```inspect.ps1```
  5. Edit run.ps1 and uncommend the platform you want to run, the default is arm64
     - ```run.ps1```
     - This will run a container for the uncommented architecture and print it
     - Remove the image when done because docker run will not change architectures already if an image already exists
     - ```docker images```
     - ``` docker rmi <IMAGE ID>```
  6. Edit run.ps1 and select a different architecture and run again
     - ```run.ps1```
     - This will run a container for the uncommented architecture and print it
     - Repeat as needed to change architectures

For more info about Docker on Arm refer to the articles below.

[Getting started with Docker on Arm](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-on-arm)

[Getting started with Docker for Arm using buildx on Linux](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux)
