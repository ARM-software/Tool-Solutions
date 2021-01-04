#----------------------------------------------------------------------------
# Base image derived from Ubuntu 18.04 used as the starting point for all stages
# Install all needed tools and setup the user account
# The final release image could be optimized to be smaller if needed
#---------------------------------------------------------------------------
FROM ubuntu:18.04

RUN echo "root:docker" | chpasswd

RUN apt-get update && \
      apt-get -y install sudo git vim wget make curl zip xterm bc build-essential libsndfile1 software-properties-common && \
      rm -rf /var/lib/apt/lists/*
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update
RUN apt install python3.7 python3.7-dev python3.7-venv -y



RUN useradd --create-home -s /bin/bash -m user1 && echo "user1:docker" | chpasswd && adduser user1 sudo

WORKDIR /home/user1

USER user1

#----------------------------------------------------------------------------
# Install Arm Compiler 6
#---------------------------------------------------------------------------

RUN mkdir /home/user1/tmp
ADD --chown=user1:user1  DS500-BN-00026-r5p0-17rel0.tgz /home/user1/tmp
RUN /home/user1/tmp/install_x86_64.sh --i-agree-to-the-contained-eula --no-interactive -d /home/user1/AC6
RUN rm -rf /home/user1/tmp

#----------------------------------------------------------------------------
# Install cmake 3.15.6 required to build the Ethos-U55 driver
#---------------------------------------------------------------------------
RUN mkdir /home/user1/cmake
RUN wget -N https://github.com/Kitware/CMake/releases/download/v3.15.6/cmake-3.15.6-Linux-x86_64.sh
RUN bash /home/user1/cmake-3.15.6-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/home/user1/cmake
RUN rm cmake-3.15.6-Linux-x86_64.sh

#---------------------------------------------------------------------------------------------------------------------------
# Copy all the scripts and software dependencies to build the tensorflow lite micro applications into the software directory
#---------------------------------------------------------------------------------------------------------------------------
RUN mkdir -p /home/user1/software/resources
COPY --chown=user1:user1 software/install_dependencies.sh /home/user1/software
COPY --chown=user1:user1 software/build_tflite_micro_app.sh /home/user1/software
COPY --chown=user1:user1 software/tensorflow_20200702.tar.gz /home/user1/software/tensorflow_20200702.tar.gz
COPY --chown=user1:user1 software/resources /home/user1/software/resources

#----------------------------------------------------------------------------
# Download and Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#---------------------------------------------------------------------------
RUN mkdir /home/user1/system
WORKDIR /home/user1/system
RUN wget https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.12_57.tgz
RUN tar xzvf FVP_Corstone_SSE-300_Ethos-U55_11.12_57.tgz
RUN ./FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula -d /home/user1/system/FVP_Corestone_SSE-300_Ethos-U55 --no-interactive
RUN rm -rf FVP_Corstone_SSE-300_Ethos-U55_11.12_57.tgz FVP_Corstone_SSE-300_Ethos-U55.sh
RUN mkdir -p /home/user1/system/FVP_Corestone_SSE-300_Ethos-U55/resources
COPY --chown=user1:user1 system/resources /home/user1/system/FVP_Corestone_SSE-300_Ethos-U55/resources
COPY --chown=user1:user1 system/run-fvp.sh /home/user1/system/FVP_Corestone_SSE-300_Ethos-U55/run-fvp.sh


WORKDIR /home/user1

RUN echo "export ARMLMD_LICENSE_FILE=7010@localhost" >> /home/user1/.bashrc
RUN echo "export PATH=$PATH:/home/user1/AC6/bin:/home/user1/cmake/bin" >> /home/user1/.bashrc
RUN echo "export ARM_TOOL_VARIANT=ult" >> /home/user1/.bashrc


