# # Build command
# # 	docker build -t arm-tool-base:latest --build-arg license_path=/path/to/license .
#
# # Run command
# # 	docker run -it arm-tool-base:latest


FROM centos:6.6

ENV DEBIAN_FRONTEND=noninteractive

RUN yum -y groupinstall "Additional Development" "Compatibility Libraries" "Development tools" "Perl Support"  && yum clean all
RUN yum -y install gstreamer-plugins-base && yum clean all || true


# # set the license path from command line argument
ARG license_path
ENV ARMLMD_LICENSE_FILE=$license_path

# # create /arm-tools/ dirctory to install all tools into
RUN mkdir /arm-tools/		&&\
	chmod 755 /arm-tools/



### 	Tool Version Select 	###

ARG CMS_INSTALL=Arm-CycleModel-release-v11_0_4
ARG CMS_DIR=Arm-CycleModel-release-v11_0_4

ARG CMS_SYSC_INSTALL=Arm-CycleModelSystemC-Runtime-files-Linux64-v11.0.1
ARG CMS_SYSC_DIR=Arm-CycleModelSystemC-Runtime-files-Linux64-v11.0.1





### 	Install Fast Models 	###

# # copy file from same directory as this Dockerfile
COPY $CMS_INSTALL.tgz /home/
COPY $CMS_SYSC_INSTALL.tgz /home/

