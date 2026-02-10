# SPDX-FileCopyrightText: Copyright 2020-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Specify DOCKER_IMAGE_MIRROR if you want to use a mirror of hub.docker.com
ARG BASE_IMAGE=python:3.12-slim
ARG DOCKER_IMAGE_MIRROR=""

# ============================
# Workshop
# ============================
FROM ${DOCKER_IMAGE_MIRROR}${BASE_IMAGE} AS workshop

ARG TENSORFLOW_WHEEL

ENV DEBIAN_FRONTEND=noninteractive
ENV DOCKER_USER=debian

RUN test "$(arch)" = "aarch64"

# Install OS dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends protobuf-compiler wget && \
    rm -rf /var/lib/apt/lists/*

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

# Install uv for quicker package installations
RUN pip install uv==0.9.29

# Update to newer pip/setuptools/wheel (setuptools >= 70.0.0 due to CVE-2024-6345
# and CVE-2025-47273, wheel >= 0.38.0 due to CVE-2022-40898) and delete old system
# version (we essentially use apt:python3-pip to bootstrap pip)
RUN uv pip install --upgrade pip~=25.2 setuptools~=78.1.1 wheel~=0.45.1

# Install non-TensorFlow requirements
COPY --chown=$DOCKER_USER:$DOCKER_USER requirements.txt .
RUN uv pip install -r requirements.txt --no-deps

# Bring wheels into image
RUN test -n "${TENSORFLOW_WHEEL}"
COPY --chown=$DOCKER_USER:$DOCKER_USER ${TENSORFLOW_WHEEL} /home/$DOCKER_USER/

# Install wheel
RUN set -eux && uv pip install "$(basename "$TENSORFLOW_WHEEL")" && rm "$(basename "$TENSORFLOW_WHEEL")"

# Copy examples/tests into image
COPY --chown=$DOCKER_USER:$DOCKER_USER examples/ /home/$DOCKER_USER/
COPY --chown=$DOCKER_USER:$DOCKER_USER tensorflow/ /home/$DOCKER_USER/tensorflow

# ============================
# Final flat image
# ============================
FROM ${DOCKER_IMAGE_MIRROR}${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV DOCKER_USER=debian

# Runtime OS bits + UI
RUN set -eux && \
    if ! id "$DOCKER_USER" >/dev/null 2>&1; then useradd --create-home -s /bin/bash "$DOCKER_USER"; fi && \
    echo '[ -n "$TERM" -a -r "$HOME/welcome.txt" ] && cat "$HOME/welcome.txt"' >> /etc/bash.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$HOME/.venv/bin:$PATH"' >> /etc/bash.bashrc

# Bring in prepped env + code
COPY --from=workshop --chown=$DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER /home/$DOCKER_USER

USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER

# Ensure the venv is on PATH in the final image as well
ENV PATH="/home/$DOCKER_USER/.venv/bin:$PATH"

CMD ["bash", "-l"]
