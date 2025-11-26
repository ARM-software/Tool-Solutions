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
FROM ${DOCKER_IMAGE_MIRROR}ubuntu:24.04 AS workshop

ARG USERNAME

ARG TORCH_WHEEL
ENV TORCH_WHEEL=$TORCH_WHEEL

ARG TORCH_AO_WHEEL
ENV TORCH_AO_WHEEL=$TORCH_AO_WHEEL

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
    && rm -rf /var/lib/apt/lists/*

# DOCKER_USER for the Docker user
ENV DOCKER_USER=${USERNAME}

# Create user only if it doesn't already exist
RUN id "$DOCKER_USER" >/dev/null 2>&1 || useradd --create-home -s /bin/bash -m "$DOCKER_USER"

# Set password and add to sudo group
RUN echo "$DOCKER_USER:ToolSolutionsPyTorch" | chpasswd && adduser "$DOCKER_USER" sudo || true

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
# python3 -m pip now uses the /usr/local install
RUN apt-get update && apt-get purge -y \
      python3-pip \
      python3-setuptools \
      python3-pkg-resources \
      python3-wheel \
      python3-distutils \
      python3-lib2to3 \
      python3-dev \
      python3.12-dev \
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

# Base requirements for examples, excluding torch and torch*
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
# Note: torchvision is pinned to a nightly build, this can be updated
# at the next vision release, and the `--extra-index-url` removed.
RUN pip install --pre torchvision==0.25.0.dev20251104 --index-url https://download.pytorch.org/whl/nightly/cpu --no-deps

# We need --no-deps because the torch version won't match the versions on torch*
RUN pip install "$(basename "$TORCH_WHEEL")" --no-deps \
    && rm "$(basename "$TORCH_WHEEL")"

# We need --no-deps because this won't match the torch version
RUN pip install "$(basename "$TORCH_AO_WHEEL")" --no-deps \
    && rm "$(basename "$TORCH_AO_WHEEL")"

# Setup Examples and tests
COPY examples/ /home/$DOCKER_USER/
COPY pytorch/test /home/$DOCKER_USER/pytorch/test

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
