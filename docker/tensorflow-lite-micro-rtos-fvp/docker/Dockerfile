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


RUN useradd --create-home -s /bin/bash -m user1 \
  && echo "user1:docker" | chpasswd \
  && adduser user1 sudo

RUN chmod 777 /etc/sudoers \
  && echo "user1 ALL=(ALL) NOPASSWD: /bin/kill" >> /etc/sudoers \
  && chmod 440 /etc/sudoers

WORKDIR /home/user1

USER user1

#---------------------------------------------------------------------------
# Install Arm Compiler 6
#---------------------------------------------------------------------------
# mkdir unnecessary?
RUN mkdir /home/user1/tmp 
ADD --chown=user1:user1 DS500-BN-00026-r5p0-17rel0.tgz /home/user1/tmp
RUN /home/user1/tmp/install_x86_64.sh --i-agree-to-the-contained-eula --no-interactive -d /home/user1/AC6
RUN rm -rf /home/user1/tmp


#---------------------------------------------------------------------------
# Install newer CMake, 3.15.6 or newer is required to build the Ethos-U55 driver
#---------------------------------------------------------------------------
RUN mkdir /home/user1/cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-Linux-x86_64.sh
RUN bash cmake-3.19.1-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/home/user1/cmake
RUN rm cmake-3.19.1-Linux-x86_64.sh

#----------------------------------------------------------------------------
# Download and Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#----------------------------------------------------------------------------
RUN mkdir /home/user1/tmp 
RUN mkdir /home/user1/system
ADD --chown=user1:user1 FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz /home/user1/tmp
RUN /home/user1/tmp/FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula -d /home/user1/system/FVP_Corestone_SSE-300_Ethos-U55 --no-interactive
RUN rm -rf /home/user1/tmp

# Setup Environment Variables
ENV PATH="/home/user1/AC6/bin:/home/user1/cmake/bin:/home/user1/system/FVP_Corestone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4:${PATH}"

ARG ARMLMD_LICENSE_FILE
RUN echo "export ARMLMD_LICENSE_FILE=${ARMLMD_LICENSE_FILE}" >> /home/user1/.bashrc
RUN echo "export ARM_TOOL_VARIANT=ult" >> /home/user1/.bashrc

# Create FVP SSE300 Alias to simplify command for running the FVP
RUN echo "FVP_CS300() {" >> ~/.bashrc && \
    echo "  /home/user1/system/FVP_Corestone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4/FVP_Corstone_SSE-300_Ethos-U55 \"\$@\"" >> ~/.bashrc && \
    echo "}" >> ~/.bashrc && \
    echo "export -f FVP_CS300" >> ~/.bashrc

RUN mkdir /home/user1/work
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
RUN sed -i 's/\r//' linux_build.sh
RUN chmod +x linux_build.sh
RUN ./linux_build.sh

#----------------------------------------------------------------------------
# Add run script
#----------------------------------------------------------------------------
COPY --chown=user1:user1 run_demo_app.sh .
RUN sed -i 's/\r//' run_demo_app.sh
RUN chmod +x run_demo_app.sh

EXPOSE 9090:9090 22:22 

ENTRYPOINT echo docker | sudo -S service ssh restart && bash