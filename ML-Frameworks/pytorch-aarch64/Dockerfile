# *******************************************************************************
# Copyright 2020-2025 Arm Limited and affiliates.
# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:22.04

ARG TORCH_WHEEL
ENV TORCH_WHEEL=$TORCH_WHEEL

ARG TORCH_AO_WHEEL
ENV TORCH_AO_WHEEL=$TORCH_AO_WHEEL

# TODO make sure Openblas is 0.3.28
# And mlcommons is 4.1
RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

RUN apt-get update && apt-get install -y \
    # We need pip to install things, this will also bring in a minimal python3
    python3-pip \
    # So that we can call python instead of python3
    python-is-python3 \
    # To allow users to install new things if they want
    sudo \
    # includes tcmalloc, which can speed up some models, see README.md for more details
    google-perftools \
    # Git
    git \
    && rm -rf /var/lib/apt/lists/*

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

# Base requirements for examples, excluding torch
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Check TORCH_WHEEL was set and copy
RUN test -n "$TORCH_WHEEL"
COPY $TORCH_WHEEL /home/$DOCKER_USER/

# Check TORCH_AO_WHEEL was set and copy
RUN test -n "$TORCH_AO_WHEEL"
COPY $TORCH_AO_WHEEL /home/$DOCKER_USER/

# Install our dev build of torch alongside fixed nightly builds of torchaudio
# and torchvision (following instructions from
# https://pytorch.org/get-started/locally/ for torch*) torch is a prereq of
# torch* so installing them at the same time means that _only_ the right torch
# is installed. torch is also a prereq of torchdata, but torchdata has no
# nightly, so we are more lax with requirement. You may want to use
# https://pypi.org/project/change-wheel-version/ to set your built torch wheel
# to match the git commit date, so that it is compatibile with the other built
# torch* nightly builds
RUN pip install "$(basename "$TORCH_WHEEL")" \
    torchaudio==2.6.0.dev20241218 \
    torchdata~=0.7.1 \
    torchvision==0.22.0.dev20241218 \
    torchtune==0.5.0.dev20241218 \
    --extra-index-url https://download.pytorch.org/whl/nightly/cpu \
    && rm "$(basename "$TORCH_WHEEL")"

RUN pip install  --force-reinstall "$(basename "$TORCH_AO_WHEEL")" && rm "$(basename "$TORCH_AO_WHEEL")"

# Setup Examples
COPY examples/ /home/$DOCKER_USER/

# Llm examples depends on torchchat
RUN sudo mkdir -p /home/ubuntu/gen_ai_utils/ && \
    cd /home/ubuntu/gen_ai_utils/ && \
    sudo git clone https://github.com/pytorch/torchchat.git -b main && \
    cd torchchat && \
    sudo git config --global --add safe.directory /home/ubuntu/gen_ai_utils/torchchat && \
    sudo git checkout 90749d280bbc116fcc121a1eda1b60f1dba5b675

CMD ["bash", "-l"]
