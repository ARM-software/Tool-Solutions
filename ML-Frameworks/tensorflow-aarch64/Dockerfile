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
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:24.04 AS workshop

ARG USERNAME

ARG TENSORFLOW_WHEEL
ENV TENSORFLOW_WHEEL=$TENSORFLOW_WHEEL

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

RUN apt-get update && apt-get install -y \
    # We need pip to install things, this will also bring in a minimal python3
    python3-pip \
    # So that we can create a virtual environment
    python3-venv \
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
ENV DOCKER_USER=${USERNAME}

# Create user only if it doesn't already exist
RUN id "$DOCKER_USER" >/dev/null 2>&1 || useradd --create-home -s /bin/bash -m "$DOCKER_USER"

# Set password and add to sudo group
RUN echo "$DOCKER_USER:ToolSolutionsTensorFlow" | chpasswd && adduser "$DOCKER_USER" sudo || true

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Import profile for bash
COPY bash_profile /home/$DOCKER_USER/.bash_profile
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER/.bash_profile

# Add welcome message to warn about dev quality
COPY welcome.txt /home/$DOCKER_USER/
RUN echo '[ ! -z "$TERM" -a -r /home/$DOCKER_USER/welcome.txt ] && cat /home/$DOCKER_USER/welcome.txt' >> /etc/bash.bashrc
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >>  /etc/bash.bashrc

# Grab the SECURITY.md from the root directory
COPY --from=rootdir SECURITY.md /home/$DOCKER_USER/

# Remove system Python stuff. Should be safe to wipe after the line above, because
# python3 -m pip now uses the /usr/local install. Also removes unused protobuf
# packages to resolve CVE-2025-4565.
RUN apt-get update && apt-get purge -y \
      python3-pip \
      python3-setuptools \
      python3-pkg-resources \
      python3-wheel \
      python3-distutils \
      python3-lib2to3 \
      python3-dev \
      python3.12-dev \
      libprotobuf32t64 \
      libprotobuf-lite32t64 \
      libprotoc32t64 \
      protobuf-compiler \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Move to userland
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

# Create a per-user virtualenv and use that for everything Python
RUN python -m venv /home/$DOCKER_USER/.venv

# Make the venv python/pip first on PATH for all subsequent layers and at runtime
ENV PATH="/home/$DOCKER_USER/.venv/bin:$PATH"

# Update to newer pip/setuptools/wheel (setuptools >= 70.0.0 due to CVE-2024-6345
# and CVE-2025-47273, wheel >= 0.38.0 due to CVE-2022-40898) and delete old system
# version (we essentially use apt:python3-pip to bootstrap pip)
RUN pip install --upgrade pip~=25.2 setuptools~=78.1.1 wheel~=0.45.1

# Check TENSORFLOW_WHEEL was set and copy
RUN test -n "$TENSORFLOW_WHEEL"
COPY $TENSORFLOW_WHEEL /home/$DOCKER_USER/

# Install our dev build of TensorFlow.
RUN pip install "$(basename "$TENSORFLOW_WHEEL")" \
    && rm "$(basename "$TENSORFLOW_WHEEL")"

# Base requirements for examples, excluding TensorFlow
COPY requirements.txt ./
RUN pip install -r requirements.txt --no-deps

# Setup Examples and tests
COPY --chown=$DOCKER_USER examples/ /home/$DOCKER_USER/
COPY --chown=$DOCKER_USER tensorflow/ /home/$DOCKER_USER/tensorflow

# Move build into final image as a single layer.
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:24.04

ARG USERNAME

ENV DOCKER_USER=${USERNAME}

COPY --from=workshop / /
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER

USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER

# Ensure the venv is on PATH in the final image as well
ENV PATH="/home/$DOCKER_USER/.venv/bin:$PATH"

CMD ["bash", "-l"]
