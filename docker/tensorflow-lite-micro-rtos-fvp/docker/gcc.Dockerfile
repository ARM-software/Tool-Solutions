#----------------------------------------------------------------------------
# Step 0: Create base imagewith some basice configuration
#----------------------------------------------------------------------------
FROM multiarch/ubuntu-core:amd64-bionic as base_image

SHELL ["/bin/bash", "-c"]
LABEL maintainer="tobias.andersson@arm.com"

RUN echo "root:docker" | chpasswd

#----------------------------------------------------------------------------
# Step 1: Use Gosu to create user dynamically
#----------------------------------------------------------------------------
FROM base_image as user_configuration

RUN apt-get -y update \
  && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl \
    gpg gpg-agent dirmngr 

RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu


#----------------------------------------------------------------------------
# Install newer CMake, 3.15.6 or newer is required to build the Ethos-U55 driver
#----------------------------------------------------------------------------
FROM base_image as cmake_install
RUN apt-get -y update \
  && apt-get -y install wget
RUN wget https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-Linux-x86_64.sh \
  && mkdir -p /usr/local/cmake \
  && bash cmake-3.19.1-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/usr/local/cmake

#----------------------------------------------------------------------------
# Step 4: Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#----------------------------------------------------------------------------
FROM base_image as fvp_install
ADD downloads/FVP_Corstone_SSE-300_Ethos-U55_11.14_24.tgz /tmp
RUN /tmp/FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula -d /usr/local/FVP_Corstone_SSE-300_Ethos-U55 --no-interactive 

#----------------------------------------------------------------------------
# Step 5: Install vela
#----------------------------------------------------------------------------
FROM base_image as vela_install
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update \
  && apt-get -y install python3 python3-venv python3-dev python3-pip
RUN python3 -m venv /usr/local/.vela
ENV PATH=/usr/local/.vela/bin:$PATH
RUN pip install --upgrade pip setuptools \
  && pip install ethos-u-vela pillow

#----------------------------------------------------------------------------
# Step 6: Copy dependenices to the armclang image
#----------------------------------------------------------------------------
FROM base_image as armclang_main
RUN apt-get -y update \
  && apt-get -y install sudo git vim wget make telnet curl zip xterm bc build-essential libsndfile1 software-properties-common \
    python3 python3-venv \
  && rm -rf /var/lib/apt/lists/*

#---------------------------------------------------------------------------
# COPY over user configuration from user_configuration image
#---------------------------------------------------------------------------
COPY --from=user_configuration /usr/local/bin/gosu /usr/local/bin/gosu
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#---------------------------------------------------------------------------
# COPY over cmake from cmake_install image
#---------------------------------------------------------------------------
COPY --from=cmake_install /usr/local/cmake /usr/local/cmake

#---------------------------------------------------------------------------
# COPY over cmake from vela_install image
#---------------------------------------------------------------------------
COPY --from=vela_install /usr/local/.vela /usr/local/.vela

#---------------------------------------------------------------------------
# Install GCC GNU Compiler
#---------------------------------------------------------------------------
ADD downloads/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 /usr/local/

#----------------------------------------------------------------------------
# Copy FVP installation from fvp_install image
#----------------------------------------------------------------------------
COPY --from=fvp_install /usr/local/FVP_Corstone_SSE-300_Ethos-U55 /usr/local/FVP_Corstone_SSE-300_Ethos-U55

#----------------------------------------------------------------------------
# Setup Environment Variables
#----------------------------------------------------------------------------
ENV PATH="/usr/local/.vela/bin:/usr/local/gcc-arm-none-eabi-10-2020-q4-major/bin:/usr/local/cmake/bin:/usr/local/FVP_Corstone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4:${PATH}"
ENV COMPILER="gcc"

#----------------------------------------------------------------------------
# Add path to helper scripts 
#----------------------------------------------------------------------------
ADD scripts/convert_scripts /usr/local/convert_scripts
ENV PATH=/usr/local/convert_scripts:$PATH
RUN sed -i 's/\r//' /usr/local/convert_scripts/*.sh \
  && chmod +x /usr/local/convert_scripts/*.sh

#----------------------------------------------------------------------------
# Workdir
#----------------------------------------------------------------------------
RUN mkdir -p -m777 /work
WORKDIR /work

#----------------------------------------------------------------------------
# Add build Script
#----------------------------------------------------------------------------
COPY linux_build.sh .
RUN  sed -i 's/\r//' linux_build.sh \
  && chmod +x linux_build.sh

#----------------------------------------------------------------------------
# Add run script
#----------------------------------------------------------------------------
COPY run_demo_app.sh .
RUN sed -i 's/\r//' run_demo_app.sh \
  && chmod +x run_demo_app.sh

COPY docker/bashrc /etc/bash.bashrc
RUN  sed -i 's/\r//' /etc/bash.bashrc

CMD ["/bin/bash"]