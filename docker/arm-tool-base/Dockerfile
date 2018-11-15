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
RUN apt-get install -y apt-utils
RUN apt-get install -y \
 #Python
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
#___________2__________ 
#__________FMs_________
#### Local zip:
COPY FastModels_11-3-030_Linux64.tgz /home/

RUN 	tar xvzf /home/FastModels_11-3-030_Linux64.tgz && \
		cd FastModels_11-3-030_Linux64 && \
		./setup.sh --i-accept-the-license-agreement && \
		rm /home/FastModels_11-3-030_Linux64.tgz && \
		rm -r /FastModels_11-3-030_Linux64/
  

#______________________
#___________3__________ 
#__________DS-5_________
COPY DS500-BN-00019-r5p0-28rel1.tgz /home/
	
		# ds5 installer doesn't work with the default tar binary, change to bsdtar then change back.
RUN 	mkdir /DS500-BN-00019-r5p0-28rel1/ && \
		tar xvzf /home/DS500-BN-00019-r5p0-28rel1.tgz --directory /DS500-BN-00019-r5p0-28rel1/ && \
		cd DS500-BN-00019-r5p0-28rel1/ && \
		apt-get install -y bsdtar && \
		cp $(which tar) $(which tar)~ && \
		ln -sf $(which bsdtar) $(which tar) && \
		./install.sh --i-agree-to-the-contained-eula --no-interactive -d ~/ARM/DS-5v5.28.0/ && \
 		mv $(which tar)~ $(which tar) && \
		PATH=$PATH:/usr/local/DS-5_v5.28.1/bin && \
		rm /home/DS500-BN-00019-r5p0-28rel1.tgz && \
		rm -r /DS500-BN-00019-r5p0-28rel1/
			
