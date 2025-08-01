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
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:22.04 AS workshop

ARG USERNAME

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
ENV DOCKER_USER=${USERNAME}

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

# Base requirements for examples, excluding torch and torch*
RUN pip install --upgrade pip
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Check TORCH_WHEEL was set and copy
RUN test -n "$TORCH_WHEEL"
COPY $TORCH_WHEEL /home/$DOCKER_USER/

# Check TORCH_AO_WHEEL was set and copy
RUN test -n "$TORCH_AO_WHEEL"
COPY $TORCH_AO_WHEEL /home/$DOCKER_USER/

# Install torch* packages, these should be the latest stable (but pinned to
# minor). We need --no-deps here because the torch* packages depend on the
# corresponding version of torch. Note: if you add something to this list, you
# will need to manually add their dependencies. We don't use the nightly
# versions which corresponding to our torch build because they can disappear,
# and we usually don't need features from the nightlies.
# Note: torchvision is currently pinned to a nightly build, this can be updated
# at the next vision release, and the `--extra-index-url` removed.
RUN pip install \
    torchaudio~=2.6.0 \
    torchdata~=0.11.0 \
    torchvision~=0.22.0.dev20250403 \
    torchtune~=0.5.0 \
    --extra-index-url https://download.pytorch.org/whl/nightly/cpu \
    --no-deps

# We need --no-deps because the torch version won't match the versions on torch*
RUN pip install "$(basename "$TORCH_WHEEL")" --no-deps \
    && rm "$(basename "$TORCH_WHEEL")"

# We need --no-deps because this won't match the torch version
RUN pip install "$(basename "$TORCH_AO_WHEEL")" --no-deps \
    && rm "$(basename "$TORCH_AO_WHEEL")"

# Setup Examples
COPY examples/ /home/$DOCKER_USER/

# Move build into final image as a single layer.
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:22.04

ARG USERNAME

ENV DOCKER_USER=${USERNAME}

COPY --from=workshop / /
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER

USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER
CMD ["bash", "-l"]
