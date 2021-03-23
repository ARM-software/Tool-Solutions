FROM ubuntu:18.04
SHELL ["/bin/bash", "-c"]
LABEL maintainer="tobias.andersson@arm.com"

RUN echo "root:docker" | chpasswd

#---------------------------------------------------------------------
# Update and install necessary packages.
#---------------------------------------------------------------------
RUN apt-get -y update \
  && apt-get -y install --no-install-recommends \
    sudo git wget make gcc curl \
    zip unzip libatomic1 ca-certificates \
    xxd imagemagick \
    python3 python3-venv python3-dev python3-pip \
  && rm -rf /var/lib/apt/lists/*

#----------------------------------------------------------------------------
# add user
#----------------------------------------------------------------------------
RUN useradd --create-home -s /bin/bash -m user1 \
  && echo "user1:docker" | chpasswd \
  && adduser user1 sudo

#----------------------------------------------------------------------------
# install vela
#----------------------------------------------------------------------------
RUN python3 -m venv /usr/local/.vela
ENV PATH=/usr/local/.vela/bin:${PATH}
RUN pip install --upgrade wheel pip setuptools \
  && pip install ethos-u-vela

#---------------------------------------------------------------------------
# Install Arm Compiler 6
#---------------------------------------------------------------------------
ADD DS500-BN-00026-r5p0-17rel0.tgz /tmp/
RUN /tmp/install_x86_64.sh --i-agree-to-the-contained-eula --no-interactive -d /usr/local \
  && rm -rf /tmp/* 
ARG LICENSE_FILE
ENV ARMLMD_LICENSE_FILE=$LICENSE_FILE
ENV ARM_TOOL_VARIANT=ult

#---------------------------------------------------------------------------
# Install newer CMake, 3.15.6 or newer is required to build the Ethos-U55 driver
#---------------------------------------------------------------------------
RUN wget https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-Linux-x86_64.sh \
  && bash cmake-3.19.1-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/usr/local \
  && rm cmake-3.19.1-Linux-x86_64.sh

#----------------------------------------------------------------------------
# Download and Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#----------------------------------------------------------------------------
ADD FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz /tmp/
RUN /tmp/FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula -d /usr/local/FVP_Corstone_SSE-300_Ethos-U55 --no-interactive \
  && rm -rf /tmp/*
ENV PATH=/usr/local/FVP_Corstone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4:${PATH}
    
#----------------------------------------------------------------------------
# Bashrc
#----------------------------------------------------------------------------
COPY docker/bashrc /etc/bash.bashrc
RUN  sed -i 's/\r//' /etc/bash.bashrc

#----------------------------------------------------------------------------
# Workdir
#----------------------------------------------------------------------------
USER user1
WORKDIR /home/user1

#----------------------------------------------------------------------------
# Copy source code to image  
#----------------------------------------------------------------------------
COPY --chown=user1:user1 sw sw

#----------------------------------------------------------------------------
# Add path to helper scripts 
#----------------------------------------------------------------------------
ENV PATH=/home/user1/sw/convert_scripts:$PATH
RUN  sed -i 's/\r//' /home/user1/sw/convert_scripts/*.sh
RUN chmod +x /home/user1/sw/convert_scripts/*.sh

#----------------------------------------------------------------------------
# Download dependencies
#----------------------------------------------------------------------------
RUN git clone -b 21.02 https://git.mlplatform.org/ml/ethos-u/ethos-u.git \
  && cd ethos-u \
  && python3 fetch_externals.py -c 21.02.json fetch

#----------------------------------------------------------------------------
# Build Example Application with armclang
#----------------------------------------------------------------------------
COPY --chown=user1:user1 linux_build.sh .
RUN  sed -i 's/\r//' linux_build.sh \
  && chmod +x linux_build.sh \
  && ./linux_build.sh -c armclang

#----------------------------------------------------------------------------
# Add run script
#----------------------------------------------------------------------------
COPY --chown=user1:user1 run_demo_app.sh .
RUN sed -i 's/\r//' run_demo_app.sh \
  && chmod +x run_demo_app.sh
