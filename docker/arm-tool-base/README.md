# Docker image: arm-tool-base
This dockerfile creates an image with Arm tools pre-installed on it for ease of use. 

## Legal Note
NOTE: Before installing Arm tools from the command line with the "--i-accept-the-license-agreement" option or similar option, you will be required to agree to be bound by and automatically accept the included the terms and conditions of the relevant Arm End User License Agreement (EULA) and agree to the terms and conditions detailed therein. This condition applies to installation and use of any product updates or new versions of the product will be subject to as the terms and conditions of the relevant Arm EULA that applies at the time of install. 

## Usage instructions
In order to properly build and run this image, follow these steps:

  1. Create a new directory, for example called 'arm-tool-base-repo'.
  2. Download the most recent versions  of Arm tools and place the tar files in the 'arm-tool-base-repo'. 
     - [Fast Models](https://developer.arm.com/products/system-design/fast-models)
     - [DS-5](https://developer.arm.com/products/software-development-tools/ds-5-development-studio)
  3. Download this dockerfile and place it in 'arm-tool-base-repo'
  4. Enter the 'arm-tool-base-repo' and build the dockerfile with the following syntax from the command line or terminal:
     - ```docker build -t arm-tool-base:latest --build-arg license_path=${ARMLMD_LICENSE_PATH} .```
     - **NOTE:** This assumes that the environmental variable 'ARMLMD_LICENSE_PATH' is set to a floating license on a server.
     - Wait until the build completes; this will take some time.
  5. Run the docker image
     - ```docker run -it arm-tool-base:latest```
     - This will run an interactive container of the arm-tool-base image.
  6. In the docker container, source the setup script to initialize all Arm tools
     - ```. /init.sh```
     
Now you are inside a docker container with Arm tools installed and ready to use.
