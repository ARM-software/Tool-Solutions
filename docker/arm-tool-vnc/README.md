# Docker image: arm-tool-vnc
This dockerfile adds remote desktop capabilities to the arm-tool-base image containing Arm tools pre-installed on it for ease of use in a graphical environment. 

## Legal Note
NOTE: Before installing Arm tools from the command line with the "--i-accept-the-license-agreement" option or similar option, you will be required to agree to be bound by and automatically accept the included the terms and conditions of the relevant Arm End User License Agreement (EULA) and agree to the terms and conditions detailed therein. This condition applies to installation and use of any product updates or new versions of the product will be subject to as the terms and conditions of the relevant Arm EULA that applies at the time of install. 

## Usage instructions
The VNC server is configured to start automatically as a deamon by default. In the below instructions the port number '1111' is opened, which can be changed to the desired port number.
In order to properly build and run this image, follow these steps:

  1. Ensure that the latest arm-tool-base Dockerfile from this repository is downloaded and built on your desired machine, as this image requires the arm-tool-base image to work.
  2. Change the password in the 'password.txt' file to a secure one. The password must be at least 8 characters.
  3. Build this Docker image by running the following with all files in this directory present:   >> docker build -t arm-tool-vnc:latest .
  4. Run this Docker image in detached mode by running:   >> docker run -d -p 1111:5901 arm-tool-vnc:latest
  5. Run this Docker image in interactive mode (useful for viewing logs in stdout) by running the above 'docker run' command without the '-d' option.
  6. Connect to the Docker vnc server by any VNC client; I use the lightweight 'xtightvncviewer' for on Linux. Connect to '0.0.0.0:1111', enter your password, and the connection should be made.
     
Now you are inside a docker container in a graphicial interface with Arm tools installed and ready to use.
