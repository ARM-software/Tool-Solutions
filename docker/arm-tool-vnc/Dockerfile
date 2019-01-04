# /home/zach/Training-Docker/Dockerfile-interactive

FROM arm-tool-base:latest

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --fix-missing \
	xfce4	 	\
	xfce4-terminal 	\
	tightvncserver 	\
	xrdp

########
# Edit Desktop elements
########

# Edit xfce4 desktop to enable tab complete on terminal 
# NEED /root/.config/ folder to exist, which requires default config to be selected....once you log in. chicken and egg issue.
#RUN sed -i 's+<property name="&lt;Super&gt;Tab" type="string" value="switch_window_key"/>+<property name="&lt;Super&gt;Tab" type="empty"/>+g' /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml

# Set user for VNC server (USER is only for build)
ENV USER root

# Default password
COPY password.txt .
RUN 	cat password.txt password.txt | vncpasswd && \
	rm password.txt

# Expose VNC port
EXPOSE 5901

# Set XRDP to use TightVNC port
RUN sed -i '0,/port=-1/{s/port=-1/port=5901/}' /etc/xrdp/xrdp.ini

# Copy VNC script that handles restarts
COPY vnc.sh /opt/
CMD . /opt/vnc.sh
	 			


