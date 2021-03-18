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

## add user
RUN useradd --create-home -s /bin/bash -m user1 \
  && echo "user1:docker" | chpasswd \
  && adduser user1 sudo \
  && chmod 777 /etc/sudoers \
  && echo "user1 ALL=(ALL) NOPASSWD: /bin/kill" >> /etc/sudoers \
  && chmod 440 /etc/sudoers

WORKDIR /home/user1
USER user1

# Download dependencies
RUN mkdir /home/user1/work \
  && git clone -b 21.02 https://git.mlplatform.org/ml/ethos-u/ethos-u.git /home/user1/work/ethos-u \
  && cd work/ethos-u \
  && python3 fetch_externals.py -c 21.02.json fetch

#---------------------------------------------------------------------------
# Install GCC GNU Compiler (in tensorflow tree to prevent TF to download in build)
#---------------------------------------------------------------------------
# mkdir unnecessary?
RUN mkdir /home/user1/tmp 
COPY --chown=user1:user1 gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 /home/user1/tmp/
RUN cd tmp \
  && tar xf gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 \
  && mkdir -p /home/user1/work/ethos-u/core_software/tensorflow/tensorflow/lite/micro/tools/make/downloads/ \
  && mv /home/user1/tmp/gcc-arm-none-eabi-10-2020-q4-major /home/user1/work/ethos-u/core_software/tensorflow/tensorflow/lite/micro/tools/make/downloads/gcc_embedded \
  && rm -rf /home/user1/tmp
ENV PATH="/home/user1/work/ethos-u/core_software/tensorflow/tensorflow/lite/micro/tools/make/downloads/gcc_embedded/bin/:${PATH}"

#---------------------------------------------------------------------------
# Install newer CMake, 3.15.6 or newer is required to build the Ethos-U55 driver
#---------------------------------------------------------------------------
RUN mkdir /home/user1/cmake \
  && wget https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-Linux-x86_64.sh \
  && bash cmake-3.19.1-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/home/user1/cmake \
  && rm cmake-3.19.1-Linux-x86_64.sh

#----------------------------------------------------------------------------
# Download and Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#----------------------------------------------------------------------------
RUN mkdir /home/user1/tmp \
  && mkdir /home/user1/system
ADD --chown=user1:user1 FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz /home/user1/tmp
RUN /home/user1/tmp/FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula -d /home/user1/system/FVP_Corstone_SSE-300_Ethos-U55 --no-interactive \
  && rm -rf /home/user1/tmp

# Setup Environment Variables
ENV PATH="/home/user1/cmake/bin:/home/user1/system/FVP_Corstone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4:${PATH}"

# Create FVP SSE300 Alias to simplify command for running the FVP
RUN echo "FVP_CS300() {" >> ~/.bashrc && \
    echo "  /home/user1/system/FVP_Corstone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4/FVP_Corstone_SSE-300_Ethos-U55 \"\$@\"" >> ~/.bashrc && \
    echo "}" >> ~/.bashrc && \
    echo "export -f FVP_CS300" >> ~/.bashrc

WORKDIR /home/user1/work

#----------------------------------------------------------------------------
# install vela
#----------------------------------------------------------------------------
RUN python3 -m venv .vela
ENV PATH=/home/user1/work/.vela/bin:$PATH
RUN pip install --upgrade pip setuptools \
  && pip install ethos-u-vela

#----------------------------------------------------------------------------
# Copy application source to the image
#----------------------------------------------------------------------------
COPY --chown=user1:user1 sw sw

#----------------------------------------------------------------------------
# add path to helper scripts 
#----------------------------------------------------------------------------
ENV PATH=/home/user1/work/sw/convert_scripts:$PATH
RUN chmod +x /home/user1/work/sw/convert_scripts/*.sh

#----------------------------------------------------------------------------
# Build Example Application
#----------------------------------------------------------------------------
COPY --chown=user1:user1 linux_build.sh .
RUN sed -i 's/\r//' linux_build.sh \
  && chmod +x linux_build.sh \
  && ./linux_build.sh -c gcc

#----------------------------------------------------------------------------
# Add run script
#----------------------------------------------------------------------------
COPY --chown=user1:user1 run_demo_app.sh .
RUN sed -i 's/\r//' run_demo_app.sh \
  && chmod +x run_demo_app.sh

EXPOSE 9090:9090 22:22 

ENTRYPOINT echo docker | sudo -S service ssh restart && bash