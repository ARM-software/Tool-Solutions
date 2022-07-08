# *******************************************************************************
# Copyright 2020-2022 Arm Limited and affiliates.
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

# ========
# Stage 1: Base image including OS and key packages
# ========
ARG njobs
ARG default_py_version=3.8

FROM ubuntu:20.04 AS pytorch-base
ARG default_py_version
ENV PY_VERSION="${default_py_version}"

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

RUN apt-get -y update && \
    apt-get -y install \
      software-properties-common \
      wget

# Add additional repositories
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
      | gpg --dearmor - \
      | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null

RUN add-apt-repository ppa:ubuntu-toolchain-r/test && \
    add-apt-repository 'deb https://apt.kitware.com/ubuntu/ focal main'

# Install core OS packages
RUN apt-get -y install \
      accountsservice \
      apport \
      at \
      autoconf \
      bc \
      build-essential \
      cmake \
      cpufrequtils \
      curl \
      ethtool \
      g++-10 \
      gcc-10 \
      gettext-base \
      gfortran-10 \
      git \
      iproute2 \
      iputils-ping \
      lxd \
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
      libsox-fmt-all \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libxslt-dev \
      locales \
      lsb-release \
      lvm2 \
      moreutils \
      net-tools \
      open-iscsi \
      openjdk-8-jdk \
      openssl \
      pciutils \
      policykit-1 \
      python${PY_VERSION} \
      python${PY_VERSION}-dev \
      python${PY_VERSION}-distutils \
      python${PY_VERSION}-venv \
      python3-pip \
      python-openssl \
      rsync \
      rsyslog \
      snapd \
      scons \
      sox \
      ssh \
      sudo \
      time \
      udev \
      unzip \
      ufw \
      uuid-runtime \
      vim \
      xz-utils \
      zip \
      zlib1g-dev

# Set default gcc, python and pip versions
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 1 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 1 && \
    update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-10 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# DOCKER_USER for the Docker user
ENV DOCKER_USER=ubuntu

# Setup default user
RUN useradd --create-home -s /bin/bash -m $DOCKER_USER && echo "$DOCKER_USER:Portland" | chpasswd && adduser $DOCKER_USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Import profile for bash
COPY bash_profile /home/$DOCKER_USER/.bash_profile
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER/.bash_profile
COPY patches/welcome.txt /home/$DOCKER_USER/.
RUN echo '[ ! -z "$TERM" -a -r /home/$DOCKER_USER/welcome.txt ] && cat /home/$DOCKER_USER/welcome.txt' >> /etc/bash.bashrc

# ========
# Stage 2: augment the base image with some essential libs
# ========
FROM pytorch-base AS pytorch-libs
ARG njobs
ARG cpu
ARG arch
ARG blas_cpu
ARG blas_ncores
ARG acl_arch

ENV NP_MAKE="${njobs}" \
    CPU="${cpu}" \
    ARCH="${arch}" \
    BLAS_CPU="${blas_cpu}" \
    BLAS_NCORES="{blas_ncores}" \
    ACL_ARCH="${acl_arch}"

# Key version numbers
ENV ACL_VERSION="v22.05" \
    OPENBLAS_VERSION=0.3.20 \
    NINJA_VERSION=1.9.0

# Package build parameters
ENV PROD_DIR=/opt \
    PACKAGE_DIR=packages

# Make directories to hold package source & build directories (PACKAGE_DIR)
# and install build directories (PROD_DIR).
RUN mkdir -p $PACKAGE_DIR && \
    mkdir -p $PROD_DIR

# Common compiler settings
ENV CC=gcc \
    CXX=g++ \
    BASE_CFLAGS="-mcpu=${CPU} -march=${ARCH} -O3" \
    BASE_LDFLAGS="" \
    LD_LIBRARY_PATH=""

# Build OpenBLAS from source
COPY scripts/build-openblas.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-openblas.sh
ENV OPENBLAS_DIR=$PROD_DIR/openblas
ENV LD_LIBRARY_PATH=$OPENBLAS_DIR/lib:$LD_LIBRARY_PATH

# Build Arm Compute Library from source
COPY scripts/build-acl.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-acl.sh
ENV ACL_ROOT_DIR=$PROD_DIR/ComputeLibrary

# Build ninja from source
COPY scripts/build-ninja.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-ninja.sh
ENV PATH=$PROD_DIR/ninja/$NINJA_VERSION:$PATH

# ========
# Stage 3: install essential python dependencies into a venv
# ========
FROM pytorch-libs AS pytorch-tools
ARG njobs
ARG default_py_version
ARG cpu
ARG arch

ENV PY_VERSION="${default_py_version}" \
    NP_MAKE="${njobs}" \
    CPU="${cpu}" \
    ARCH="${arch}"
# Key version numbers
ENV NUMPY_VERSION=1.21.5 \
    SCIPY_VERSION=1.7.3 \
    NPY_DISTUTILS_APPEND_FLAGS=1

# Using venv means this can be done in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Setup a Python virtual environment
ENV VIRTUAL_ENV=/home/$DOCKER_USER/python3-venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Rust into user-space, needed for transformers dependencies
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/$DOCKER_USER/.cargo/bin:${PATH}"

# Install some basic python packages needed for NumPy
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir "setuptools>=41.0.0" six mock wheel cython

# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-numpy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-numpy.sh

# Install some  basic python packages needed for SciPy
RUN pip install --no-cache-dir pybind11==2.6.2 pyangbind pythran
# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-scipy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-scipy.sh

# Install some more essentials.
RUN pip install --no-cache-dir hypothesis pyyaml pytest
RUN pip install --no-cache-dir matplotlib
RUN pip install --no-cache-dir pillow==6.1 lmdb
RUN pip install --no-cache-dir ck==1.55.5 absl-py pycocotools typing_extensions
RUN pip install --no-cache-dir transformers pandas

# Install OpenCV into our venv,
# Note: Scripts are provided to build and install OpenCV from the
# GitHub repository. These are no longer used by default in favour of the
# opencv-python package, in this case opencv-python-headless.
# Uncomment code block '1' below, and comment out code block '2' to build
# from the GitHub sources.
# --
# 1 - build from GitHub sources:
#COPY scripts/build-opencv.sh $PACKAGE_DIR/.
#RUN $PACKAGE_DIR/build-opencv.sh
# --
# 2 - install opencv-python-headless
RUN pip install --no-cache-dir scikit-build
# enum34 is not compatable with Python 3.6+, and not required
# it is installed as a dependency for an earlier package and needs
# to be removed in order for the OpenCV build to complete.
RUN pip uninstall enum34 -y
RUN pip install --no-cache-dir opencv-python-headless

CMD ["bash", "-l"]

# ========
# Stage 4: build PyTorch
# ========
FROM pytorch-libs AS pytorch-dev
ARG njobs
ARG onednn_opt
ARG default_py_version
ARG cpu
ARG bazel_version
ARG build_xla

ENV ONEDNN_BUILD="${onednn_opt}" \
    NP_MAKE="${njobs}" \
    CPU="${cpu}" \
    XLA_BUILD="${build_xla}"

# Key version numbers
ENV PY_VERSION="${default_py_version}" \
    ONEDNN_VERSION="v2.6" \
    TORCH_VERSION=1.12.0 \
    TORCHXLA_VERSION=1.12.0 \
    TORCHVISION_VERSION=0.13.0 \
    TORCHDATA_VERSION=0.4.0 \
    TORCHTEXT_VERSION=0.13.0 \
    BZL_VERSION="${bazel_version}"

# Use a PACKAGE_DIR in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Copy in the Python virtual environment
ENV VIRTUAL_ENV=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=pytorch-tools $VIRTUAL_ENV /home/$DOCKER_USER/python3-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Build PyTorch
COPY scripts/build-pytorch.sh $PACKAGE_DIR/.
COPY patches/onednn.patch $PACKAGE_DIR/.
COPY scripts/build-torchtext.sh $PACKAGE_DIR/.
COPY scripts/build-torchdata.sh $PACKAGE_DIR/.

COPY patches/torch_xla.patch $PACKAGE_DIR/.
COPY patches/xla_cpu_enhancements.patch $PACKAGE_DIR/.

# TODO: Switch to bazelisk for bazel installation
# Get Bazel binary for AArch64
COPY scripts/get-bazel.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/get-bazel.sh
ENV PATH=$PACKAGE_DIR/bazel:$PATH

RUN $PACKAGE_DIR/build-pytorch.sh
# Install torchvision, torchdata and torchtext
RUN pip install --no-cache-dir torchvision==$TORCHVISION_VERSION

ENV VENV_PACKAGE_DIR=$VENV_DIR/lib/python$PY_VERSION/site-packages
# Build torchtext from source to workaround the undefined symbol issue with the wheel
RUN $PACKAGE_DIR/build-torchtext.sh
# Build torchdata from source because there is no wheel for v0.4.0
RUN $PACKAGE_DIR/build-torchdata.sh

CMD ["bash", "-l"]

# ========
# Stage 5: Install benchmarks and examples
# ========
FROM pytorch-libs AS pytorch
ARG njobs

WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

# Copy in the Python virtual environment
ENV VIRTUAL_ENV=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=pytorch-dev $VIRTUAL_ENV /home/$DOCKER_USER/python3-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Examples, benchmarks, and associated 'helper' scripts will be installed
# in $EXAMPLE_DIR.
ENV EXAMPLE_DIR=/home/$DOCKER_USER/examples
ENV MLCOMMONS_DIR=$EXAMPLE_DIR/MLCommons
RUN mkdir -p $EXAMPLE_DIR
RUN mkdir -p $MLCOMMONS_DIR

# Clone and install  MLCommons (MLPerf)
COPY scripts/build-mlcommons.sh $MLCOMMONS_DIR/.
COPY patches/mlcommons_bert.patch $MLCOMMONS_DIR/.
COPY patches/mlcommons_rnnt.patch $MLCOMMONS_DIR/.
COPY patches/pytorch_native.patch $MLCOMMONS_DIR/.
RUN $MLCOMMONS_DIR/build-mlcommons.sh
RUN rm -f $MLCOMMONS_DIR/build-mlcommons.sh
# Copy scripts to download dataset and models
COPY scripts/download-dataset.sh $MLCOMMONS_DIR/.
COPY scripts/download-model.sh $MLCOMMONS_DIR/.

# Install missing Python package dependencies required to run examples
RUN pip install --no-cache-dir requests tqdm boto3 iopath sox unidecode inflect toml
RUN pip install --no-cache-dir future onnx==1.8.1
RUN pip install --no-cache-dir 'librosa==0.8.0'

# Copy examples
ENV EXAMPLE_DIR=/home/$DOCKER_USER/examples
ADD examples $EXAMPLE_DIR
COPY patches/welcome_verbose.txt /home/$DOCKER_USER/welcome.txt

CMD ["bash", "-l"]
