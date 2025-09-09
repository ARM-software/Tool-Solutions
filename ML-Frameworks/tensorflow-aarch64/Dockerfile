# *******************************************************************************
# Copyright 2020-2025 Arm Limited and affiliates.
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

# Specify DOCKER_IMAGE_MIRROR if you want to use a mirror of hub.docker.com
ARG DOCKER_IMAGE_MIRROR=""
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:22.04 AS workshop

ARG USERNAME

ARG TENSORFLOW_WHEEL
ENV TENSORFLOW_WHEEL=$TENSORFLOW_WHEEL

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

RUN apt-get update && apt-get install -y \
    # We need pip to install things, this will also bring in a minimal python3
    python3-pip \
    # So that we can call python instead of python3
    python-is-python3 \
    # To allow users to install new things if they want
    sudo \
    # Git
    git \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update
RUN apt-get install -y protobuf-compiler
RUN apt-get install -y wget

# DOCKER_USER for the Docker user
ENV DOCKER_USER=ubuntu

# Setup default user
RUN useradd --create-home -s /bin/bash -m $DOCKER_USER && echo "$DOCKER_USER:Portland" | chpasswd && adduser $DOCKER_USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Import profile for bash
COPY bash_profile /home/$DOCKER_USER/.bash_profile
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER/.bash_profile

# Add welcome message to warn about dev quality
COPY welcome.txt /home/$DOCKER_USER/.
RUN echo '[ ! -z "$TERM" -a -r /home/$DOCKER_USER/welcome.txt ] && cat /home/$DOCKER_USER/welcome.txt' >> /etc/bash.bashrc
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >>  /etc/bash.bashrc

# Move to userland
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

# Check TENSORFLOW_WHEEL was set and copy
RUN test -n "$TENSORFLOW_WHEEL"
COPY $TENSORFLOW_WHEEL /home/$DOCKER_USER/

# Install our dev build of TensorFlow.
RUN pip install \
    "$(basename "$TENSORFLOW_WHEEL")" \
    && rm \
    "$(basename "$TENSORFLOW_WHEEL")"

# Base requirements for examples, excluding TensorFlow
COPY requirements.txt ./
RUN pip install -r requirements.txt --no-deps

# Setup Examples and tests
COPY --chown=$DOCKER_USER examples/ /home/$DOCKER_USER/
COPY --chown=$DOCKER_USER tensorflow/ /home/$DOCKER_USER/tensorflow

# Move build into final image as a single layer.
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:22.04

ARG USERNAME

ENV DOCKER_USER=${USERNAME}

COPY --from=workshop / /
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER

USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER
CMD ["bash", "-l"]
