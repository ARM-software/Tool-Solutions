#----------------------------------------------------------------------------
# Base image derived from Ubuntu 18.04 used as the starting point for all stages
# Install all needed tools and setup the user account
# The final release image could be optimized to be smaller if needed
#----------------------------------------------------------------------------

FROM ubuntu:18.04 as base

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN echo "root:armnn" | chpasswd

RUN apt-get update -y && \
      apt-get -y install sudo vim iputils-ping net-tools curl wget dialog software-properties-common apt-utils chrpath git make cmake gcc g++ autoconf autogen libtool scons unzip bzip2 libpcre3 libpcre3-dev python3.6-dev build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev python3-pip python3-dev python3-opencv


RUN useradd --create-home -s /bin/bash -m ubuntu && echo "ubuntu:armnn" | chpasswd && adduser ubuntu sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

WORKDIR /home/ubuntu
USER ubuntu


#----------------------------------------------------------------------------
# Build the entire Arm NN stack
#----------------------------------------------------------------------------
FROM armswdev/armnn:base AS build

WORKDIR /home/ubuntu
USER ubuntu

# Build machine and target machine linux/arm/v7  linux/arm64 or linux/amd64
ARG TARGETPLATFORM
ARG BUILDPLATFORM

COPY --chown=ubuntu:ubuntu build-armnn.sh /home/ubuntu

RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then /home/ubuntu/build-armnn.sh -a armv7a ; else /home/ubuntu/build-armnn.sh ; fi



#----------------------------------------------------------------------------------
# Build the developer image to compile C++ applications and use Python with Arm NN
# Only libraries and header files are needed
#----------------------------------------------------------------------------------
FROM armswdev/armnn:base AS dev

WORKDIR /home/ubuntu 
USER ubuntu 

RUN mkdir -p ~/armnn/lib
RUN mkdir -p ~/armnn/include
RUN mkdir -p ~/armnn/pyarmnn
COPY --from=armswdev/armnn:build  /home/ubuntu/armnn-devenv/pkg/install/lib/lib* /home/ubuntu/armnn/lib
COPY --from=armswdev/armnn:build  /home/ubuntu/armnn-devenv/armnn/build/lib* /home/ubuntu/armnn/lib
COPY --from=armswdev/armnn:build  /home/ubuntu/armnn-devenv/armnn/include/ /home/ubuntu/armnn/include
COPY --from=armswdev/armnn:build  /home/ubuntu/armnn-devenv/armnn/python/pyarmnn/ /home/ubuntu/armnn/pyarmnn
RUN sudo cp -r /home/ubuntu/armnn/include/armnn* /usr/include
RUN sudo cp -r /home/ubuntu/armnn/lib/lib* /usr/lib
COPY --chown=ubuntu:ubuntu clone.sh /home/ubuntu
RUN /home/ubuntu/clone.sh 
ENV ARMNN_INCLUDE "/home/ubuntu/armnn/include"
ENV ARMNN_LIB "/home/ubuntu/armnn/lib"


