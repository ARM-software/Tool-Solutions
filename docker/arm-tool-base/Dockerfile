# # Build command
# # 	docker build -t arm-tool-base:latest --build-arg license_path=/path/to/license .
#
# # Run command
# # 	docker run -it arm-tool-base:latest




FROM ubuntu:16.04

MAINTAINER Zach

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y



### 	System Functionality 	###

RUN apt-get install -y apt-utils 	\
    iputils-ping 					\
	python2.7

RUN apt-get install -y 	\
 # Python
	python-pip 

RUN apt-get install -y --fix-missing \
 # FMs
	lsb-core 			\
	libxext6 			\
	libsm6 				\
	libxcursor1 		\
	libxft2 			\
	libxrandr2 			\
	libxt6 				\
	libxinerama1 		\
 # ArmDS and DS-5
	libasound2 			\
	libatk1.0-0 		\
	libcairo2 			\
	libgl1 				\
	libglu1 			\
	libgtk2.0-0 		\
	libxi6 				\
	libxtst6 			\
	gcc-multilib 		\
	libstdc++6 			\
	libwebkitgtk-1.0-0 

# # set the license path from command line argument
ARG license_path
ENV ARMLMD_LICENSE_FILE=$license_path

# # create /arm-tools/ dirctory to install all tools into
RUN mkdir /arm-tools/		&&\
	chmod 755 /arm-tools/



### 	Tool Version Select 	###

ARG FM_INSTALL=FastModels_11-5-033_Linux64
ARG FM_DIR=FastModelsTools_11.5

ARG ArmDS_INSTALL=DS000-BN-00001-r18p0-00rel0
ARG ArmDS_VERSION=2018.0
ARG ArmDS_DIR=ArmDS

#ARG DS5_INSTALL=DS500-BN-00019-r5p0-28rel1
#ARG DS5_DIR=DS-5v5.28.0



### 	Install Fast Models 	###

# # copy file from same directory as this Dockerfile
COPY $FM_INSTALL.tgz /home/

# # install program and delete artifacts
RUN 	tar xvzf /home/$FM_INSTALL.tgz 			&&\
		cd $FM_INSTALL 							&&\
		./setup.sh --i-accept-the-license-agreement --basepath /arm-tools/ 	&&\
		rm /home/$FM_INSTALL.tgz 				&&\
		rm -r /$FM_INSTALL/ 							

# # add setup to /init.sh 
RUN 	echo 	"set +e; . /arm-tools/$FM_DIR/source_all.sh" >> /init.sh




### 	Install ArmDS	###

# # copy file from same directory as this Dockerfile
COPY $ArmDS_INSTALL.tgz /home/

# # install program and delete artifacts
RUN 	mkdir /$ArmDS_INSTALL/ 					&&\
    	tar xvzf /home/$ArmDS_INSTALL.tgz --directory /$ArmDS_INSTALL/ &&\
		cd $ArmDS_INSTALL/ 						&&\
		./armds-$ArmDS_VERSION.sh --i-agree-to-the-contained-eula --no-interactive -d /arm-tools/$ArmDS_DIR/ 	&&\
		rm /home/$ArmDS_INSTALL.tgz 			&&\
		rm -r /$ArmDS_INSTALL/

# # add setup to /init.sh 
RUN	echo 	"export PATH=$PATH:/arm-tools/$ArmDS_DIR/sw/ARMCompiler6.9/bin:/arm-tools/$ArmDS_DIR/bin:/arm-tools/$ArmDS_DIR/sw/java/bin"    >> /init.sh &&\
	echo 	"export ARMDS_CDB_PATH=/arm-tools/$ArmDS_DIR/sw/debugger/configdb"   >> /init.sh 			&&\
	echo 	"export DBGHWCONFIG_PLATFORMFILES=/arm-tools/$ArmDS_DIR/sw/debughw/PlatformFiles"   >> /init.sh 	&&\
	echo 	"export ARM_PRODUCT_PATH=/arm-tools/$ArmDS_DIR/sw/mappings"   >> /init.sh 			&&\
	echo 	"export ARMDS_HOME=/arm-tools/$ArmDS_DIR"   >> /init.sh 




### 	Install DS5 	###

# # copy file from same directory as this Dockerfile
# COPY $DS5_INSTALL.tgz /home/

# # install program and delete artifacts
# # DS5 installer doesn't work with the default tar binary, change to bsdtar then change back.
# RUN 	mkdir /$DS5_INSTALL/ 					&&\
#		tar xvzf /home/$DS5_INSTALL.tgz --directory /$DS5_INSTALL/ &&\
#		cd $DS5_INSTALL/ 						&&\
#		apt-get install -y bsdtar 				&&\
#		cp $(which tar) $(which tar)~ 			&&\
#		ln -sf $(which bsdtar) $(which tar) 	&&\
#		./install.sh --i-agree-to-the-contained-eula --no-interactive -d /arm-tools/$DS5_DIR/ &&\
#		mv $(which tar)~ $(which tar) 			&&\
#		rm /home/$DS5_INSTALL.tgz 				&&\
#		rm -r /$DS5_INSTALL/

# # add setup to /init.sh 
# RUN	echo 	"export PATH=$PATH:/arm-tools/$DS5_DIR/sw/ARMCompiler6.9/bin:/arm-tools/$DS5_DIR/bin:/arm-tools/$DS5_DIR/sw/java/bin"    >> /init.sh &&\
#	echo 	"export DS5_CDB_PATH=/arm-tools/$DS5_DIR/sw/debugger/configdb"   >> /init.sh 			&&\
#	echo 	"export DBGHWCONFIG_PLATFORMFILES=/arm-tools/$DS5_DIR/sw/debughw/PlatformFiles"   >> /init.sh 	&&\
#	echo 	"export ARM_PRODUCT_PATH=/arm-tools/$DS5_DIR/sw/mappings"   >> /init.sh 			&&\
#	echo 	"export DS5_HOME=/arm-tools/$DS5_DIR" >> /init.sh 
