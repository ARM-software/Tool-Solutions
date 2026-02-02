# SPDX-FileCopyrightText: Copyright 2020-2026 Arm Limited and affiliates.
# SPDX-FileCopyrightText: Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

# Specify DOCKER_IMAGE_MIRROR if you want to use a mirror of hub.docker.com
ARG PYTHON_IMAGE=python:3.12-slim
ARG DOCKER_IMAGE_MIRROR=""

# ============================
# Workshop
# ============================
FROM ${DOCKER_IMAGE_MIRROR}${PYTHON_IMAGE} AS workshop

ARG USERNAME
ARG TORCH_WHEEL
ARG TORCH_AO_WHEEL

ENV DEBIAN_FRONTEND=noninteractive
ENV DOCKER_USER=${USERNAME}

RUN test "$(arch)" = "aarch64"

# Install OS dependencies
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Create user
RUN set -eux && id "$DOCKER_USER" >/dev/null 2>&1 || useradd --create-home -s /bin/bash "$DOCKER_USER"

# Copy bash profile and welcome text into user home
COPY --chown=$DOCKER_USER:$DOCKER_USER bash_profile /home/$DOCKER_USER/.bash_profile
COPY --chown=$DOCKER_USER:$DOCKER_USER welcome.txt /home/$DOCKER_USER/welcome.txt

# Switch to userland
USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER

# Create virtual environment
RUN python -m venv /home/$DOCKER_USER/.venv
ENV PATH="/home/$DOCKER_USER/.venv/bin:${PATH}"

# Update to newer pip/setuptools/wheel (setuptools >= 70.0.0 due to CVE-2024-6345
# and CVE-2025-47273, wheel >= 0.38.0 due to CVE-2022-40898) and delete old system
# version (we essentially use apt:python3-pip to bootstrap pip)
RUN pip install --upgrade pip~=25.2 setuptools~=78.1.1 wheel~=0.45.1

# Install non-torch requirements
COPY --chown=$DOCKER_USER:$DOCKER_USER requirements.txt .
RUN pip install -r requirements.txt

# Bring wheels into image
RUN test -n "${TORCH_WHEEL}" && test -n "${TORCH_AO_WHEEL}"
COPY --chown=$DOCKER_USER:$DOCKER_USER ${TORCH_WHEEL} /home/$DOCKER_USER/
COPY --chown=$DOCKER_USER:$DOCKER_USER ${TORCH_AO_WHEEL} /home/$DOCKER_USER/

# Install wheels
RUN set -eux && pip install --no-deps "$(basename "$TORCH_WHEEL")" && rm "$(basename "$TORCH_WHEEL")"
RUN set -eux && pip install --no-deps "$(basename "$TORCH_AO_WHEEL")" && rm "$(basename "$TORCH_AO_WHEEL")"
RUN pip install --pre torchvision==0.25.0.dev20260111 --index-url https://download.pytorch.org/whl/nightly/cpu --no-deps

# Copy examples/tests into image
COPY --chown=$DOCKER_USER:$DOCKER_USER examples/ /home/$DOCKER_USER/
COPY --chown=$DOCKER_USER:$DOCKER_USER pytorch/test /home/$DOCKER_USER/pytorch/test

# ============================
# Final flat image
# ============================
FROM ${DOCKER_IMAGE_MIRROR}${PYTHON_IMAGE}

ARG USERNAME
ENV DEBIAN_FRONTEND=noninteractive
ENV DOCKER_USER=${USERNAME}

# Runtime OS bits + UI
RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    if ! id "$DOCKER_USER" >/dev/null 2>&1; then useradd --create-home -s /bin/bash "$DOCKER_USER"; fi && \
    echo '[ -n "$TERM" -a -r "$HOME/welcome.txt" ] && cat "$HOME/welcome.txt"' >> /etc/bash.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$HOME/.venv/bin:$PATH"' >> /etc/bash.bashrc

# Bring in prepped env + code
COPY --from=workshop --chown=$DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER /home/$DOCKER_USER

USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER

ENV PATH="/home/$DOCKER_USER/.venv/bin:${PATH}"

CMD ["bash", "-l"]
