# # Build command
# # 	docker build -t arm-tool-base-cms:latest --build-arg license_path=/path/to/license .
#
# # Run command
# # 	docker run -it arm-tool-base-cms:latest bash


FROM centos:6.6

ENV DEBIAN_FRONTEND=noninteractive

RUN yum -y groupinstall "Additional Development" "Compatibility Libraries" "Development tools" "Perl Support"  && yum clean all
RUN yum -y install gstreamer-plugins-base && yum clean all || true
RUN yum -y install tar && yum -y install vim-enhanced || true


# # set the license path from command line argument
ARG license_path
ENV ARMLMD_LICENSE_FILE=$license_path


### 	Tool Version Select 	###
ARG CMS_INSTALL=Arm-CycleModel-release-v11_0_4
ARG CMS_SYSC_INSTALL=Arm-CycleModelSystemC-Runtime-files-Linux64-v11.0.1


### 	Install Cycle Models 	###

# # copy file from same directory as this Dockerfile
COPY $CMS_INSTALL.tgz /home/
COPY $CMS_SYSC_INSTALL.tgz /home/

# # create /arm-tools/ dirctory to install all tools into
RUN mkdir -p /arm-tools/$CMS_INSTALL		&&\
    mkdir -p /arm-tools/$CMS_SYSC_INSTALL	&&\
	chmod 755 /arm-tools/$CMS_INSTALL		&&\
	chmod 755 /arm-tools/$CMS_SYSC_INSTALL	&&\
	tar -C /arm-tools/$CMS_INSTALL      -zxvf /home/$CMS_INSTALL.tgz  		&&\
	tar -C /arm-tools/$CMS_SYSC_INSTALL -zxvf /home/$CMS_SYSC_INSTALL.tgz	&&\
	chmod 777 /arm-tools/$CMS_INSTALL/examples/ -R	&&\
	rm -rf /home/$CMS_INSTALL.tgz					&&\
	rm -rf /home/$CMS_SYSC_INSTALL.tgz

# # add setup to /init.sh 
RUN	echo	"export CARBON_HOST_ARCH=Linux64"    >> /init.sh	&&\
	echo 	"export CARBON_TARGET_ARCH=Linux64"  >> /init.sh	&&\
	echo 	"source /arm-tools/$CMS_INSTALL/etc/setup.sh"  >> /init.sh	&&\
	echo 	"source /arm-tools/$CMS_SYSC_INSTALL/ARM/ThirdPartyIP/Accellera/SystemC/2.3.1/etc/setup.sh"  >> /init.sh
