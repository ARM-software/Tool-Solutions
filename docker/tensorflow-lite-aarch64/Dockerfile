# *******************************************************************************
# Copyright 2021-2022 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************

FROM ubuntu:20.04

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

#Install core OS packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get -y install \
      autoconf \
      bc \
      build-essential \
      cmake \
      curl \
      g++-10 \
      gcc-10 \
      gettext-base \
      gfortran-10 \
      git \
      iputils-ping \
      libbz2-dev \
      libc++-dev \
      libcgal-dev \
      libffi-dev \
      libfreetype6-dev \
      libhdf5-dev \
      libjpeg-dev \
      liblzma-dev \
      libncurses5-dev \
      libncursesw5-dev \
      libpng-dev \
      libreadline-dev \
      libssl-dev \
      libsqlite3-dev \
      libxml2-dev \
      libxslt-dev \
      locales \
      moreutils \
      openssl \
      python \
      python-openssl \
      python3 \
      python3-pip \
      rsync \
      scons \
      ssh \
      sudo \
      time \
      unzip \
      vim \
      wget \
      xz-utils \
      zip \
      zlib1g-dev

# Make gcc 10 the default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 1 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-10 && \
    update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-10 1

# DOCKER_USER for the Docker user
ENV DOCKER_USER=ubuntu

# Setup default user
RUN useradd --create-home -s /bin/bash -m $DOCKER_USER && \
  echo "$DOCKER_USER:Portland" | chpasswd && adduser $DOCKER_USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Import profile for bash
COPY bash_profile /home/$DOCKER_USER/.bash_profile
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER/.bash_profile
COPY patches/welcome.txt /home/$DOCKER_USER/.
RUN echo '[ ! -z "$TERM" -a -r /home/$DOCKER_USER/welcome.txt ] && \
  cat /home/$DOCKER_USER/welcome.txt' >> /etc/bash.bashrc

ENV TF_VERSION=2.8.0

# Package build parameters
ENV PROD_DIR=/opt \
    PACKAGE_DIR=/packages

# Make directories to hold package source & build directories (PACKAGE_DIR)
# and install build directories (PROD_DIR).
RUN mkdir -p $PACKAGE_DIR && \
    mkdir -p $PROD_DIR

# Build tensorflow
COPY scripts/build-tensorflow.sh $PACKAGE_DIR/.
COPY patches/tflite.patch $PACKAGE_DIR/.
COPY scripts/libruy.mri $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-tensorflow.sh

# Build Arm Compute Library
COPY scripts/build-armcl.sh $PACKAGE_DIR/.
# This patch adds support for spin wait scheduler to ACL
COPY patches/acl.patch $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-armcl.sh

# ArmNN library
# Install development version of Boost
RUN apt-get update
RUN apt-get -y --fix-missing install libboost-all-dev
COPY scripts/build-armnn.sh $PACKAGE_DIR/.
COPY patches/flatbuffers.patch $PACKAGE_DIR/.
COPY patches/armnn.patch $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-armnn.sh

# Copy example how to run it
ENV EXAMPLE_DIR=/home/$DOCKER_USER/examples
RUN mkdir -p $EXAMPLE_DIR
RUN chown $DOCKER_USER:$DOCKER_USER $EXAMPLE_DIR
COPY --chown=$DOCKER_USER:$DOCKER_USER scripts/run_mobilenet.sh $EXAMPLE_DIR/.
RUN chmod +x $EXAMPLE_DIR/run_mobilenet.sh
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

CMD ["bash", "-l"]
