# Simple multi-architecture Docker example
A simple flask web app which prints the host architecture of the running container.

It shows how to use docker buildx to create images for multiple architectures and run them.

## Requirements
To run the example make sure Docker is installed. The example is made for [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows and Mac, but also works on Linux. 

A [Docker Hub](https://hub.docker.com/) accout is also required to save images. Have your Docker ID available.

The scripts are .ps1 to run on Windows PowerShell but they run with bash as well.

## Usage instructions
Here are the steps to run the demo:

  1. After cloning, change directory
     - ```cd flask-hello-world```
  2. Login to your Docker Hub account
     - ```docker login```
  3. Edit the build.ps1 script to use your Docker ID and run it
     - ```build.ps1```
  4. Edit the inspect.ps1 script to use your Docker ID and run it to see the multi-architecture image
     - ```inspect.ps1```
  5. Edit the run-multi-arch.ps1 to use your Docker ID and also copy and paste the sha256 values for the new image into run-multi-arch.ps1 and run it
     - ```run-multi-arch.ps1```
     - This will run a container for all 3 architectures
  6. Use a browser to connect to each instance of the flask server
     - ```localhost:5000```
     - ```localhost:5001```
     - ```localhost:5002```
  7. Use the stop.ps1 script to stop the 3 containers
     - ```stop.ps1```
  8. If you have an Arm machine available with docker edit and run the script run-native.ps to see how docker selects the right image for the machine and runs it
     - ```run-native.ps1```
     - ```localhost:80```

For more info about Docker on Arm refer to the articles below.

[Getting started with Docker on Arm](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-on-arm)

[Getting started with Docker for Arm using buildx on Linux](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux)
