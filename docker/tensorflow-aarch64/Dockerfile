# *******************************************************************************
# Copyright 2020-2021 Arm Limited and affiliates.
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
ARG bazel_mem
ARG default_py_version=3.8

FROM ubuntu:20.04 AS tensorflow-base
ARG default_py_version
ENV PY_VERSION="${default_py_version}"

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

#Install core OS packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get -y install \
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
      g++-9 \
      gcc-7 \
      gcc-9 \
      gettext-base \
      gfortran-9 \
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
      libssl-dev \
      libsqlite3-dev \
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
      ssh \
      sudo \
      time \
      udev \
      unzip \
      ufw \
      uuid-runtime \
      vim \
      wget \
      xz-utils \
      zip \
      zlib1g-dev


# Make gcc 9 and python 3(.8) the default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 1 --slave /usr/bin/g++ g++ /usr/bin/g++-9 && \
    update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-9 1 && \
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
FROM tensorflow-base AS tensorflow-libs
ARG njobs
ARG cpu
ARG arch
ARG blas_cpu

ENV NP_MAKE="${njobs}" \
    CPU="${cpu}" \
    ARCH="${arch}" \
    BLAS_CPU="${blas_cpu}"

# Key version numbers
ENV OPENBLAS_VERSION=0.3.10

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
    BASE_LDFLAGS=""

# Build OpenBLAS from source
COPY scripts/build-openblas.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-openblas.sh
ENV OPENBLAS_DIR=$PROD_DIR/openblas/$OPENBLAS_VERSION
ENV LD_LIBRARY_PATH=$OPENBLAS_DIR/lib:$LD_LIBRARY_PATH

# Build and install OpenCV from GitHub sources (needed for C++ API examples)
COPY scripts/build-opencv.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-opencv.sh

# Build and install yaml-cpp from Github source (needed for C++ API examples)
COPY scripts/build-yamlcpp.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-yamlcpp.sh

# ========
# Stage 3: install essential python dependencies into a venv
# ========
FROM tensorflow-libs AS tensorflow-tools
ARG njobs
ARG default_py_version
ARG cpu
ARG arch

ENV PY_VERSION="${default_py_version}" \
    NP_MAKE="${njobs}" \
    CPU="${cpu}" \
    ARCH="${arch}"
# Key version numbers
ENV NUMPY_VERSION=1.19.5 \
    SCIPY_VERSION=1.5.2 \
    NPY_DISTUTILS_APPEND_FLAGS=1

# Using venv means this can be done in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Setup a Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
ENV VENV_ACT=$VENV_DIR/bin/activate
RUN python -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

# Install Rust into user-space, needed for transformers dependencies
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/$DOCKER_USER/.cargo/bin:${PATH}"

# Install some basic python packages
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir "setuptools>=41.0.0" six mock wheel cython sh

# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-numpy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-numpy.sh

# Install some  basic python packages needed for SciPy
RUN pip install --no-cache-dir pybind11 pyangbind
# Build scipy from source, using OpenBLAS for BLAS calls
COPY scripts/build-scipy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-scipy.sh

# Install some TensorFlow essentials
RUN pip install --no-cache-dir keras_applications==1.0.8 --no-deps
RUN pip install --no-cache-dir keras_preprocessing==1.1.2 --no-deps
# enum34 is not compatible with Python 3.6+, and not required
# it is installed as a dependency for an earlier package and needs
# to be removed in order for the OpenCV build to complete.
RUN pip uninstall enum34 -y
RUN HDF5_DIR=/usr/lib/aarch64-linux-gnu/hdf5/serial pip install h5py==3.1.0
RUN pip install --no-cache-dir grpcio pytest
RUN pip install --no-cache-dir ck==1.55.5 absl-py pycocotools pillow==8.2.0
RUN pip install --no-cache-dir transformers pandas

# Install OpenCV into our venv (needed for MLCommons benchmarks)
RUN pip install --no-cache-dir opencv-python-headless==4.4.0.46

CMD ["bash", "-l"]

# ========
# Stage 4: install Bazel, and build tensorflow
# ========
FROM tensorflow-libs AS tensorflow-dev
ARG njobs
ARG bazel_mem
ARG onednn_opt
ARG tf_version
ARG bazel_version
ARG default_py_version
ARG cpu
ARG arch
ARG eigen_l1_cache
ARG eigen_l2_cache
ARG eigen_l3_cache

ENV NP_MAKE="${njobs}" \
    BZL_RAM="${bazel_mem}" \
    ONEDNN_BUILD="${onednn_opt}" \
    CPU="${cpu}" \
    ARCH="${arch}" \
    EIGEN_L1_CACHE="${eigen_l1_cache}" \
    EIGEN_L2_CACHE="${eigen_l2_cache}" \
    EIGEN_L3_CACHE="${eigen_l3_cache}"
# Key version numbers
ENV PY_VERSION="${default_py_version}" \
    BZL_VERSION="${bazel_version}" \
    TF_VERSION="${tf_version}"

# Use a PACKAGE_DIR in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Copy in the Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=tensorflow-tools $VENV_DIR /home/$DOCKER_USER/python3-venv
ENV PATH="$VENV_DIR/bin:$PATH"

# Get Bazel binary for AArch64
COPY scripts/get-bazel.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/get-bazel.sh
ENV PATH=$PACKAGE_DIR/bazel:$PATH

# Build TensorFlow
COPY patches/tf_acl.patch $PACKAGE_DIR/.
COPY patches/eigen_workspace.patch $PACKAGE_DIR/.
COPY patches/eigen_gebp_cache.patch  $PACKAGE_DIR/.
COPY scripts/build-tensorflow.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-tensorflow.sh

CMD ["bash", "-l"]

# ========
# Stage 5: Install benchmarks and examples
# ========
FROM tensorflow-libs AS tensorflow

WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

# Copy in the Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=tensorflow-dev $VENV_DIR /home/$DOCKER_USER/python3-venv
ENV PATH="$VENV_DIR/bin:$PATH"

# Examples, benchmarks, and associated 'helper' scripts will be installed
# in $EXAMPLE_DIR.
ENV EXAMPLE_DIR=/home/$DOCKER_USER/examples
ENV MLCOMMONS_DIR=$EXAMPLE_DIR/MLCommons
RUN mkdir -p $EXAMPLE_DIR
RUN mkdir -p $MLCOMMONS_DIR

# Clone TensorFlow benchmarks into EXAMPLE_DIR.
COPY scripts/build-benchmarks.sh $EXAMPLE_DIR/.
RUN $EXAMPLE_DIR/build-benchmarks.sh
RUN rm -f $EXAMPLE_DIR/build-benchmarks.sh

# Clone and install MLCommons (MLPerf)
COPY patches/optional-mlcommons-changes.patch $MLCOMMONS_DIR/optional-mlcommons-changes.patch
COPY patches/mlcommons_bert.patch $MLCOMMONS_DIR/mlcommons_bert.patch
COPY scripts/build-mlcommons.sh $MLCOMMONS_DIR/.
RUN $MLCOMMONS_DIR/build-mlcommons.sh
RUN rm -f $MLCOMMONS_DIR/build-mlcommons.sh
# Copy scripts to download dataset and models
COPY scripts/download-dataset.sh $MLCOMMONS_DIR/.
COPY scripts/download-model.sh $MLCOMMONS_DIR/.

# Install missing Python package dependencies required to run examples
RUN pip install --no-cache-dir pyyaml
RUN pip install --no-cache-dir tqdm

# Copy examples
COPY --chown=$DOCKER_USER:$DOCKER_USER examples $EXAMPLE_DIR

CMD ["bash", "-l"]
