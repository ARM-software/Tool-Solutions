FROM ubuntu:18.04
SHELL ["/bin/bash", "-c"]
LABEL maintainer="tobias.andersson@arm.com"

#---------------------------------------------------------------------
# Update and install necessary packages.
#---------------------------------------------------------------------
RUN apt-get -y update \
  && apt-get -y install libatomic1 \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir –m777 /work

WORKDIR /work

#----------------------------------------------------------------------------
# Download and Install Arm Corstone-300 FVP with Ethos-U55 into system directory 
#----------------------------------------------------------------------------
ADD FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz /tmp
RUN /tmp/FVP_Corstone_SSE-300_Ethos-U55.sh --i-agree-to-the-contained-eula --no-interactive \
  && rm -rf /tmp/*

# Setup Environment Variables
ENV PATH="/usr/local/FVP_Corstone_SSE-300_Ethos-U55/models/Linux64_GCC-6.4/:${PATH}"

#----------------------------------------------------------------------------
# Add run script
#----------------------------------------------------------------------------
COPY run_demo_app.sh .
RUN sed -i 's/\r//' run_demo_app.sh \
  && chmod +x run_demo_app.sh

COPY docker/bashrc /etc/bash.bashrc