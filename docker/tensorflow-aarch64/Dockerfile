# *******************************************************************************
# Copyright 2020-2023 Arm Limited and affiliates.
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
      automake \
      bc \
      build-essential \
      cmake \
      cpufrequtils \
      curl \
      ethtool \
      gcc-10 \
      g++-10 \
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
      libssl-dev \
      libsqlite3-dev \
      libtool \
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
      swig \
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
FROM tensorflow-base AS tensorflow-libs
ARG njobs
ARG cpu
ARG arch
ARG blas_cpu
ARG blas_ncores

ENV NP_MAKE="${njobs}" \
    CPU="${cpu}" \
    ARCH="${arch}" \
    BLAS_CPU="${blas_cpu}" \
    BLAS_NCORES="${blas_ncores}"

# Key version numbers
ENV OPENBLAS_VERSION=0.3.20 \
    YAML_VERSION=yaml-cpp-0.7.0

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
ENV OPENBLAS_DIR=$PROD_DIR/openblas
ENV LD_LIBRARY_PATH=$OPENBLAS_DIR/lib:$LD_LIBRARY_PATH

# Build and install OpenCV from GitHub sources (needed for C++ API examples)
COPY scripts/build-opencv.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-opencv.sh
ENV LD_LIBRARY_PATH=$PROD_DIR/opencv/install/lib:$LD_LIBRARY_PATH

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

# Install some basic python packages
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir "setuptools>=41.0.0" six mock wheel cython sh

# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-numpy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-numpy.sh

# Install some  basic python packages needed for SciPy
RUN pip install --no-cache-dir pybind11 pyangbind pythran
# Build scipy from source, using OpenBLAS for BLAS calls
COPY scripts/build-scipy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-scipy.sh

# Install some TensorFlow essentials
# enum34 is not compatible with Python 3.6+, and not required
# it is installed as a dependency for an earlier package and needs
# to be removed in order for the OpenCV build to complete.
RUN pip uninstall enum34 -y
RUN HDF5_DIR=/usr/lib/aarch64-linux-gnu/hdf5/serial pip install h5py==3.1.0
RUN pip install --no-cache-dir grpcio tensorflow-io pytest
RUN pip install --no-cache-dir ck==1.55.5 absl-py pycocotools pillow==8.2.0
RUN pip install --no-cache-dir transformers pandas

# Install OpenCV into our venv (needed for MLCommons benchmarks)
RUN pip install --no-cache-dir opencv-python-headless

# Remove dependency on HDF5 save support in Keras as this does not
# work with TensorFlow 2.11 and Transformers 4.24
COPY scripts/remove-keras-hdf-save-dependency.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/remove-keras-hdf-save-dependency.sh

CMD ["bash", "-l"]

# ========
# Stage 4: install Bazel, and build tensorflow
# ========
FROM tensorflow-libs AS tensorflow-dev
ARG njobs
ARG bazel_mem
ARG enable_onednn
ARG onednn_opt
ARG tf_version
ARG default_py_version
ARG tune
ARG arch
ARG eigen_l1_cache
ARG eigen_l2_cache
ARG eigen_l3_cache

ENV NP_MAKE="${njobs}" \
    BZL_RAM="${bazel_mem}" \
    ONEDNN_BUILD="${onednn_opt}" \
    TUNE="${tune}" \
    ARCH="${arch}" \
    EIGEN_L1_CACHE="${eigen_l1_cache}" \
    EIGEN_L2_CACHE="${eigen_l2_cache}" \
    EIGEN_L3_CACHE="${eigen_l3_cache}"
# Key version numbers
ENV PY_VERSION="${default_py_version}" \
    TF_VERSION="${tf_version}"
# Set runtime flag to enable/disable oneDNN backend
ENV TF_ENABLE_ONEDNN_OPTS="${enable_onednn}"
# Set runtime flag to ensure oneDNN primitives are cached for large batch sizes
ENV TF_MKL_OPTIMIZE_PRIMITIVE_MEMUSE=0

# Use a PACKAGE_DIR in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Copy in the Python virtual environment
ENV VIRTUAL_ENV=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=tensorflow-tools $VIRTUAL_ENV /home/$DOCKER_USER/python3-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Get Bazel binary for AArch64 using the latest Bazelisk release
RUN mkdir -p $PACKAGE_DIR/bazel
RUN bazelisk_url=$(curl -L -s https://api.github.com/repos/bazelbuild/bazelisk/releases/latest \
    | grep -o -E "https://(.*)bazelisk-linux-arm64") && \
    wget $bazelisk_url -O $PACKAGE_DIR/bazel/bazel
RUN chmod a+x $PACKAGE_DIR/bazel/bazel
ENV PATH="$PACKAGE_DIR/bazel:$PATH"

# Build TensorFlow
COPY patches/tf_acl.patch $PACKAGE_DIR/.
COPY patches/tf_fixed_format_kernels.patch $PACKAGE_DIR/.
COPY patches/compute_library.patch $PACKAGE_DIR/.
COPY patches/acl_openmp_fix.patch $PACKAGE_DIR/.
COPY patches/acl_fixed_format_kernels_striding.patch $PACKAGE_DIR/.
COPY patches/onednn_reorder_padded.patch $PACKAGE_DIR/.
COPY scripts/build-tensorflow.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-tensorflow.sh
COPY scripts/build-tensorflow-addons.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-tensorflow-addons.sh

CMD ["bash", "-l"]

# =========
# Stage 4b: install Bazel, and build tensorflow-serving
# =========
FROM tensorflow-libs AS tensorflow-serving
ARG njobs
ARG bazel_mem
ARG enable_onednn
ARG onednn_opt
ARG tfserving_version
ARG default_py_version
ARG cpu
ARG arch

ENV NP_MAKE="${njobs}" \
    BZL_RAM="${bazel_mem}" \
    ONEDNN_BUILD="${onednn_opt}" \
    CPU="${cpu}" \
    ARCH="${arch}"

# Key version numbers
ENV PY_VERSION="${default_py_version}" \
    TFSERVING_VERSION="${tfserving_version}"
# Set runtime flag to enable/disable oneDNN backend
ENV TF_ENABLE_ONEDNN_OPTS="${enable_onednn}"

# gRPC port
EXPOSE 8500
# REST port
EXPOSE 8501

# Model store within the container
ENV MODEL_BASE_PATH=/home/$DOCKER_USER/models
RUN mkdir -p ${MODEL_BASE_PATH}
# MODEL_NAME is updated at runtime with `docker run -e MODEL_NAME=<name> ...`
ENV MODEL_NAME=model

# Use a PACKAGE_DIR in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Copy in the Python virtual environment
ENV VIRTUAL_ENV=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=tensorflow-tools $VIRTUAL_ENV /home/$DOCKER_USER/python3-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Get Bazel binary for AArch64 using the latest Bazelisk release
RUN mkdir -p $PACKAGE_DIR/bazel
RUN bazelisk_url=$(curl -L -s https://api.github.com/repos/bazelbuild/bazelisk/releases/latest \
    | grep -o -E "https://(.*)bazelisk-linux-arm64") && \
    wget $bazelisk_url -O $PACKAGE_DIR/bazel/bazel
RUN chmod a+x $PACKAGE_DIR/bazel/bazel
ENV PATH="$PACKAGE_DIR/bazel:$PATH"

# Build TensorFlow Serving
COPY scripts/build-tensorflow-serving.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-tensorflow-serving.sh

# Setup entrypoint for passing model details through `docker run`
COPY scripts/tf_serving_entrypoint.sh /home/$DOCKER_USER/.
ENTRYPOINT [ "/bin/bash", "-c", "exec /home/$DOCKER_USER/tf_serving_entrypoint.sh \"${@}\"", "--" ]

# ========
# Stage 5: Install benchmarks and examples
# ========
FROM tensorflow-libs AS tensorflow
ARG enable_onednn

# Set runtime flag to enable/disable oneDNN backend
ENV TF_ENABLE_ONEDNN_OPTS="${enable_onednn}"

WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

# Copy in the Python virtual environment
ENV VIRTUAL_ENV=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=tensorflow-dev $VIRTUAL_ENV /home/$DOCKER_USER/python3-venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV LD_LIBRARY_PATH=$VIRTUAL_ENV/tensorflow/lib:$LD_LIBRARY_PATH

# Examples, benchmarks, and associated 'helper' scripts will be installed
# in $EXAMPLE_DIR.
ENV EXAMPLE_DIR=/home/$DOCKER_USER/examples
ENV MLCOMMONS_DIR=$EXAMPLE_DIR/MLCommons
RUN mkdir -p $EXAMPLE_DIR
RUN mkdir -p $MLCOMMONS_DIR

# Clone and install MLCommons (MLPerf)
COPY patches/optional-mlcommons-changes.patch $MLCOMMONS_DIR/optional-mlcommons-changes.patch
COPY patches/mlcommons_bert.patch $MLCOMMONS_DIR/mlcommons_bert.patch
COPY scripts/build-mlcommons.sh $MLCOMMONS_DIR/.
RUN $MLCOMMONS_DIR/build-mlcommons.sh
RUN rm -f $MLCOMMONS_DIR/build-mlcommons.sh

# Install missing Python package dependencies required to run examples
RUN pip install --no-cache-dir pyyaml
RUN pip install --no-cache-dir tqdm

# MLCommons ServerMode
COPY patches/Makefile.patch $MLCOMMONS_DIR/.
COPY patches/servermode.patch $MLCOMMONS_DIR/.
COPY scripts/build-boost.sh $MLCOMMONS_DIR/.
COPY scripts/build-loadgen-integration.sh $MLCOMMONS_DIR/.

# Copy scripts to download dataset and models
COPY scripts/download-dataset.sh $MLCOMMONS_DIR/.
COPY scripts/download-model.sh $MLCOMMONS_DIR/.
COPY scripts/setup-servermode.sh $MLCOMMONS_DIR/.

# Copy examples
COPY --chown=$DOCKER_USER:$DOCKER_USER examples $EXAMPLE_DIR
COPY patches/welcome_verbose.txt /home/$DOCKER_USER/welcome.txt

CMD ["bash", "-l"]
