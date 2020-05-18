# ========
# Stage 1: Base image including OS and key packages
# ========
ARG njobs

FROM ubuntu:18.04 AS pytorch-base

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

#Install core OS packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get -y install \
      autoconf \
      bc \
      build-essential \
      cmake \
      curl \
      g++-9 \
      gcc-9 \
      gettext-base \
      gfortran-9 \
      git \
      iputils-ping \
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
      moreutils \
      openjdk-8-jdk \
      openssl \
      python-openssl \
      rsync \
      ssh \
      sudo \
      time \
      unzip \
      vim \
      wget \
      xz-utils \
      zip \
      zlib1g-dev

# Make gcc 9 the default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 1 --slave /usr/bin/g++ g++ /usr/bin/g++-9 && \
    update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-9 1

# DOCKER_USER for the Docker user
ENV DOCKER_USER=ubuntu

# Setup default user
RUN useradd --create-home -s /bin/bash -m $DOCKER_USER && echo "$DOCKER_USER:Arm2020" | chpasswd && adduser $DOCKER_USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Import profile for bash
COPY bash_profile /home/$DOCKER_USER/.bash_profile
RUN chown $DOCKER_USER:$DOCKER_USER /home/$DOCKER_USER/.bash_profile


# ========
# Stage 2: augment the base image with some essential libs
# ========
FROM pytorch-base AS pytorch-libs
ARG njobs

ENV NP_MAKE="${njobs}"

# Key version numbers
ENV PY_VERSION=3.7.0 \
    OPENBLAS_VERSION=0.3.7 \
    NINJA_VERSION=1.9.0

# Package build parameters
ENV PROD_DIR=/opt \
    PACKAGE_DIR=/packages

# Make directories to hold package source & build directories (PACKAGE_DIR)
# and install build directories (PROD_DIR).
RUN mkdir -p $PACKAGE_DIR && \
    mkdir -p $PROD_DIR

# Build Arm Optimized Routines from source
# provides optimised maths library fucntions for Aarch64
# see https://github.com/ARM-software/optimized-routines
COPY scripts/build-arm_opt_routines.sh $PACKAGE_DIR/.
COPY patches/config.mk $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-arm_opt_routines.sh

# Common compiler settings for remaining builds
# this ads arm_opt_routined into the LDFLAGS by default.
ENV CC=gcc \
    CXX=g++ \
    BASE_CFLAGS="-mcpu=native" \
    BASE_LDFLAGS="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" \
    LD_LIBRARY_PATH="$PROD_DIR/arm_opt_routines/lib"

COPY scripts/build-cpython.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-cpython.sh

# Build OpenBLAS from source
COPY scripts/build-openblas.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-openblas.sh
ENV OPENBLAS_DIR=$PROD_DIR/openblas/$OPENBLAS_VERSION
ENV LD_LIBRARY_PATH=$OPENBLAS_DIR/lib:$LD_LIBRARY_PATH

# Build ninja from source
COPY scripts/build-ninja.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-ninja.sh
ENV PATH=$PROD_DIR/ninja/$NINJA_VERSION:$PATH

# ========
# Stage 3: install essential python dependencies into a venv
# ========
FROM pytorch-libs AS pytorch-tools
ARG njobs
ENV NP_MAKE="${njobs}"

# Key version numbers
ENV NUMPY_VERSION=1.17.1 \
    SCIPY_VERSION=1.4.0 \
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

# Install some basic python packages needed for NumPy
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir "setuptools>=41.0.0" six mock wheel cython

# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-numpy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-numpy.sh

# Install some  basic python packages needed for SciPy
RUN pip install --no-cache-dir pybind11 pyangbind
# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-scipy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-scipy.sh

# Install some more essentials.
RUN pip install --no-cache-dir hypothesis pyyaml pytest
RUN pip install --no-cache-dir matplotlib
RUN pip install --no-cache-dir pillow==6.1 lmdb

# Install OpenCV into our venv,
COPY scripts/build-opencv.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-opencv.sh

CMD ["bash", "-l"]

# ========
# Stage 4: build PyTorch
# ========
FROM pytorch-libs AS pytorch-dev
ARG njobs
ARG bazel_mem
ARG dnnl_opt
ENV NP_MAKE="${njobs}"

# Key version numbers
ENV TORCH_VERSION=1.4.0

# Use a PACKAGE_DIR in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Copy in the Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=pytorch-tools $VENV_DIR /home/$DOCKER_USER/python3-venv
ENV PATH="$VENV_DIR/bin:$PATH"

# Build PyTorch
COPY scripts/build-pytorch.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-pytorch.sh
RUN pip install --no-cache-dir torchvision


CMD ["bash", "-l"]

# ========
# Stage 5: install pytorch benchmarks
# ========
FROM pytorch-libs AS pytorch
ARG njobs

WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER

# Copy in the Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
COPY --chown=$DOCKER_USER:$DOCKER_USER --from=pytorch-dev $VENV_DIR /home/$DOCKER_USER/python3-venv
ENV PATH="$VENV_DIR/bin:$PATH"

# Clone PyTorch examples
# NOTE: these examples are included as a startiing point
RUN  git clone https://github.com/pytorch/examples.git

CMD ["bash", "-l"]
