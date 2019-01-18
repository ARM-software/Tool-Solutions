# # Build command
# # 	docker build -t arm-tool-interactive:latest .
#
# # Run VPN Server
# # 	docker run -p 5901:5901 --entrypoint /opt/vnc_server.sh arm-tool-interactive:latest
#
# # NoMachine Server
# #	    docker run -p 4000:4000 --cap-add=SYS_PTRACE --entrypoint /opt/nx_server.sh arm-tool-interactive:latest

FROM arm-tool-base:latest

MAINTAINER Zach

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y


### 	System Functionality 	###

# # install desktop
RUN apt-get install -y xubuntu-core	
# RUN apt-get install -y lubuntu-core	
# RUN apt-get install -y ubuntu-mate-core

# # install base system apps 
RUN apt-get update &&\
 	apt-get install -y apt-utils curl nano




### 	VNC & RDP Server 	###

# # install vncserver and RDP functionality via xrdp
RUN apt-get update &&\
    apt-get install -y tightvncserver xrdp

# # set XRDP to use TightVNC port
RUN sed -i '0,/port=-1/{s/port=-1/port=5901/}' /etc/xrdp/xrdp.ini

# # set environment varialbe USER, used by VNC server
ENV USER root




### 	NoMachine 	###

# # go to https://www.nomachine.com/download/download&id=10 to update latest
# # NOMACHINE_PACKAGE_NAME and NOMACHINE_MD5 sum:
ENV NOMACHINE_PACKAGE_NAME nomachine_6.4.6_1_amd64.deb
ENV NOMACHINE_BUILD 6.4
ENV NOMACHINE_MD5 6623e37e88b4f5ab7c39fa4a6533abf4

# # create ssh server to connect to NoMachine over a browser
# # comment it out if using NoMachine free
# RUN apt-get install -y ssh 	&&\
# 	  service ssh start 

# # download & install nomachine with correct permissions
RUN curl -fSL "http://download.nomachine.com/download/${NOMACHINE_BUILD}/Linux/${NOMACHINE_PACKAGE_NAME}" -o nomachine.deb &&\
    echo "${NOMACHINE_MD5} *nomachine.deb" | md5sum -c - &&\
    dpkg -i nomachine.deb &&\
    groupadd -r nomachine -g 433 &&\
    useradd -u 431 -r -g nomachine -d /home/nomachine -s /bin/bash -c "NoMachine" nomachine &&\
    mkdir /home/nomachine &&\
    chown -R nomachine:nomachine /home/nomachine &&\
    echo 'nomachine:nomachine' | chpasswd


# # edit Nomachine configuration to start desktop
# # replace the default desktop command (DefaultDesktopCommand) used by NoMachine with the preferred desktop
RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/startxfce4"' /usr/NX/etc/node.cfg    &&\
    sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/startxfce4"' /usr/NX/etc/server.cfg



### 	Protocol Initialization 	###

# # copy scripts that will start dameon when run
COPY vnc_server.sh /opt/
COPY nx_server.sh /opt/

# # set password
# # set for all protocols. Change the password in 'password.txt' to be as secure as possible.
ADD password.txt .
RUN cat password.txt password.txt | passwd 	&&\
    cat password.txt password.txt | vncpasswd && \
	rm password.txt

# # listen to NX port for NoMachine connection (4000 by default)
# # listen to VNC port for VNC/RDP connection (5901 by default)
EXPOSE 4000
EXPOSE 5901


#ENTRYPOINT ["/opt/nx_server.sh"]
#ENTRYPOINT ["/opt/vnc_server.sh"]
