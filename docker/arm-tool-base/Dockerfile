# Place the tool tar files in a directory ABOVE Tool-Solutions, and set BASEDIR equal to that directory. Also specify the correct path to your Arm license file. 
# For example, if the directory above Tool-Solutions is named 'arm-tool-base-repo' with the proper tar files and the Tool-Solutions directory, run the following commands:

# export BASEDIR=/path/to/arm-tool-base-repo
# export LICPATH=/path/to/license
# docker build -t arm-tool-base:latest --build-arg license_path=${LICPATH} -f ${BASEDIR}/Tool-Solutions/docker/arm-tool-base/Dockerfile ${BASEDIR}


# The Arm Docker container follows the following steps:
#	1) Image & Package Setup 
# 	2) FM Setup
#		+ Copy over FMs package
# 		+ Untar FMs
# 		+ Install FMs
# 		+ Delete tar file and install directory
# 	3) DS5 Setup
#		+ Copy over DS5 package
# 		+ Download bsdtar and use as untarer, as the default tar causes issues
# 		+ Untar DS5
# 		+ Install DS5
# 		+ Delete tar file and install directory



#______________________
#___________1__________ 
#______________________
FROM ubuntu:16.04

ARG license_path

RUN apt-get update
RUN apt-get install -y apt-utils \
     	iputils-ping \
	python2.7

RUN apt-get install -y \
 #Python
	python-pip 
	
RUN apt-get install -y --fix-missing \
 #FMs
	lsb-core \
	libxext6 \
	libsm6 \
	libxcursor1 \
	libxft2 \
	libxrandr2 \
	libxt6 \
	libxinerama1 \	
 #DS-5
	libasound2 \
	libatk1.0-0 \
	libcairo2 \
	libgl1 \
	libglu1 \
	libgtk2.0-0 \
	libxi6 \
	libxtst6 \
	gcc-multilib \
	libstdc++6 \ 
	libwebkitgtk-1.0-0 

ENV ARMLMD_LICENSE_FILE=$license_path


#______________________
#__________1.5_________ 
#Tool Variable Versions

ARG FM_INSTALL=FastModels_11-5-033_Linux64
ARG FM_DIR=FastModelsTools_11.5

ARG DS5_INSTALL=DS500-BN-00019-r5p0-28rel1
ARG DS5_DIR=DS-5v5.28.0


    
#______________________
#___________2__________ 
#__________FMs_________
#### Local zip:
COPY $FM_INSTALL.tgz /home/

RUN 	tar xvzf /home/$FM_INSTALL.tgz 							&&\
		cd $FM_INSTALL 								&&\
		./setup.sh --i-accept-the-license-agreement --basepath /arm-tools/ 	&&\
		rm /home/$FM_INSTALL.tgz 						&&\
		rm -r /$FM_INSTALL/ 							

#______________________
#___________3__________ 
#__________DS-5________
COPY $DS5_INSTALL.tgz /home/
	
		# ds5 installer doesn't work with the default tar binary, change to bsdtar then change back.
RUN 	mkdir /$DS5_INSTALL/ && \
		tar xvzf /home/$DS5_INSTALL.tgz --directory /$DS5_INSTALL/ && \
		cd $DS5_INSTALL/ && \
		apt-get install -y bsdtar && \
		cp $(which tar) $(which tar)~ && \
		ln -sf $(which bsdtar) $(which tar) && \ 
		./install.sh --i-agree-to-the-contained-eula --no-interactive -d /arm-tools/$DS5_DIR/ && \
 		mv $(which tar)~ $(which tar) && \
		rm /home/$DS5_INSTALL.tgz && \
		rm -r /$DS5_INSTALL/


#______________________
#___________3__________ 
#________Startup_______
RUN	echo 	"export PATH=$PATH:/arm-tools/$DS5_DIR/sw/ARMCompiler6.9/bin:/arm-tools/$DS5_DIR/bin:/arm-tools/$DS5_DIR/sw/java/bin"    >> /init.sh &&\
	echo 	"export DS5_CDB_PATH=/arm-tools/$DS5_DIR/sw/debugger/configdb"   >> /init.sh 			&&\
	echo 	"export DBGHWCONFIG_PLATFORMFILES=/arm-tools/$DS5_DIR/sw/debughw/PlatformFiles"   >> /init.sh 	&&\
	echo 	"export ARM_PRODUCT_PATH=/arm-tools/$DS5_DIR/sw/mappings"   >> /init.sh 			&&\
	echo 	"export DS5_HOME=/arm-tools/$DS5_DIR"   >> /init.sh 						
RUN 	echo 	"set +e; . /arm-tools/$FM_DIR/source_all.sh" >> /init.sh

