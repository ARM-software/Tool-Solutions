FROM ubuntu:18.04
SHELL ["/bin/bash", "-c"]
LABEL maintainer="tobias.andersson@arm.com"

RUN echo "root:docker" | chpasswd

#---------------------------------------------------------------------
# Update and install necessary packages.
#---------------------------------------------------------------------
RUN apt-get -y update \
  && apt-get -y install \
    sudo git vim wget make curl \
    zip xterm bc build-essential telnet \
    libsndfile1 software-properties-common \
    xxd python3 python3-venv python3-dev python3-pip \
    openssh-server \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir –m777 /work

# Download dependencies
RUN git clone -b 21.02 https://git.mlplatform.org/ml/ethos-u/ethos-u.git /work/ethos-u \
  && cd /work/ethos-u \
  && python3 fetch_externals.py -c 21.02.json fetch

#---------------------------------------------------------------------------
# Install Arm Compiler 6
#---------------------------------------------------------------------------
ADD DS500-BN-00026-r5p0-17rel0.tgz /tmp
RUN /tmp/install_x86_64.sh --i-agree-to-the-contained-eula --no-interactive -d /usr/local/AC6 \
  && rm -rf /tmp/*
ARG LICENSE_FILE
ENV ARMLMD_LICENSE_FILE=$LICENSE_FILE
ENV ARM_TOOL_VARIANT=ult

#---------------------------------------------------------------------------
# Install newer CMake, 3.15.6 or newer is required to build the Ethos-U55 driver
#---------------------------------------------------------------------------
RUN wget https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-Linux-x86_64.sh \
  && mkdir -p /usr/local/cmake \
  && bash cmake-3.19.1-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/usr/local/cmake \
  && rm cmake-3.19.1-Linux-x86_64.sh

#----------------------------------------------------------------------------
# Download and Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#----------------------------------------------------------------------------
ADD FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz /tmp
RUN /tmp/FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula -d /usr/local/FVP_Corstone_SSE-300_Ethos-U55 --no-interactive \
  && rm -rf /tmp/*

# Setup Environment Variables
ENV PATH="/usr/local/AC6/bin:/usr/local/cmake/bin:/usr/local/FVP_Corstone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4:${PATH}"

#----------------------------------------------------------------------------
# Workdir
#----------------------------------------------------------------------------
RUN mkdir -p /work
WORKDIR /work

#----------------------------------------------------------------------------
# install vela
#----------------------------------------------------------------------------
RUN python3 -m venv .vela
ENV PATH=/work/.vela/bin:$PATH
RUN pip install --upgrade pip setuptools \
  && pip install ethos-u-vela

#----------------------------------------------------------------------------
# Copy application source to the image
#----------------------------------------------------------------------------
COPY sw sw
RUN  chmod 777 -R sw

#----------------------------------------------------------------------------
# add path to helper scripts 
#----------------------------------------------------------------------------
ENV PATH=/work/sw/convert_scripts:$PATH
RUN chmod +x /work/sw/convert_scripts/*.sh

#----------------------------------------------------------------------------
# Build Example Application with armclang
#----------------------------------------------------------------------------
COPY linux_build.sh .
RUN  sed -i 's/\r//' linux_build.sh \
  && chmod +x linux_build.sh \
  && ./linux_build.sh -c armclang

#----------------------------------------------------------------------------
# Add run script
#----------------------------------------------------------------------------
COPY run_demo_app.sh .
RUN sed -i 's/\r//' run_demo_app.sh \
  && chmod +x run_demo_app.sh
  
COPY docker/bashrc /etc/bash.bashrc

EXPOSE 9090:9090 22:22 

ENTRYPOINT echo docker | sudo -S service ssh restart && bash
