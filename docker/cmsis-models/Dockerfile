FROM ubuntu:18.04

RUN echo "root:docker" | chpasswd

RUN apt-get update && \
      apt-get -y install sudo git vim wget make python3 python3-pyparsing python3-numpy python3-colorama

RUN useradd --create-home -s /bin/bash -m user1 && echo "user1:docker" | chpasswd && adduser user1 sudo

RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-Linux-x86_64.sh
RUN bash ./cmake-3.14.3-Linux-x86_64.sh --skip-license --exclude-subdir --prefix=/usr/local 

WORKDIR /home/user1

USER user1

RUN mkdir /home/user1/tmp
ADD --chown=user1:user1  DS500-BN-00026-r5p0-16rel0.tgz /home/user1/tmp
RUN /home/user1/tmp/install_x86_64.sh --i-agree-to-the-contained-eula --no-interactive -d /home/user1/AC6
RUN rm -rf /home/user1/tmp

RUN mkdir /home/user1/Platforms
COPY --chown=user1:user1 setup-cmsis.sh /home/user1
COPY --chown=user1:user1 configPlatform.cmake /home/user1
COPY --chown=user1:user1 Platforms /home/user1/Platforms
COPY --chown=user1:user1  cmake_M7F.sh /home/user1
COPY --chown=user1:user1  cmake_M55.sh /home/user1


RUN /home/user1/setup-cmsis.sh

RUN echo "export ARMLMD_LICENSE_FILE=7010@localhost" >> /home/user1/.bashrc
RUN echo "export PATH=$PATH:/home/user1/AC6/bin" >> /home/user1/.bashrc
RUN echo "export ARM_TOOL_VARIANT=ult" >> /home/user1/.bashrc

COPY --chown=user1:user1 build_basic_math.sh /home/user1

