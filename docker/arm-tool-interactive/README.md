# Docker image: arm-tool-interactive
This dockerfile adds remote desktop capabilities to the arm-tool-base image containing Arm tools pre-installed on it for ease of use in a graphical environment. This file currently supports the following protocols:
  * VNC
  * NoMachine 

## Usage instructions
The servers are configured to start automatically as a deamon by default with the appropriate run command.
In order to properly build and run this image for the desired type of connection, follow these steps:

  1. Ensure that the latest arm-tool-base Dockerfile from this repository is downloaded and built on your desired machine, as this image requires the arm-tool-base image to work.
  2. Change the password in the 'password.txt' file to a secure one. The password must be no greater than 8 characters.
  3. Build this Docker image by running the following command in this directory with all files in this directory present: 
  ```docker build -t arm-tool-interactive:latest .```
  
Next, follow the specific instructions for the desired connection.
  
### VNC Server
Connection from local Linux machines only.

  0. (optional: if running docker on a remote machine) In a terminal make an ssh connection to the remote machine using port forwarding to forward the VNC port to the local machine with the following command. The -i command is used in this case to connect with a private key but other (on no) authentication methods can be used:
  ```ssh -L 5901:localhost:5901 -i private_key.pem username@url_path```
  
  1. Run this Docker image by running the command below. This will make the dockerfile behave as a binary, starting the vnc server with the logs displaying in the terminal:   
  ```docker run -p 5901:5901 --entrypoint /opt/vnc_server.sh arm-tool-interactive:latest```

  2. In another terminal, connect to the Docker vnc server by any VNC client; I use the lightweight 'xtightvncviewer' for on Linux. Connect to 'localhost:5901', enter your password, and the connection will be made.
  
  
### NoMachine (Free)
Connection from any local machine type (Windows, Linux, Mac, etc)
  1. Run this Docker image by running the command below. This will make the dockerfile behave as a binary, starting the NoMachine server with the logs displaying in the terminal. Note that the '--cap-add=SYS_PTRACE' addition is required by Ubuntu versions 16.04 and above:   
  ```docker run -p 4000:4000 --cap-add=SYS_PTRACE --entrypoint /opt/nx_server.sh arm-tool-interactive:latest```

  2. Download, install, and open NoMachine on your machine. Set the proper connection parameters, including verification via password. Connect to the remote machine.
 
