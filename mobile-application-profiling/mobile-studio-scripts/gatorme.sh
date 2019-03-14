#!/bin/bash

# Parameters
# ==========
# $1: Android package name (default "com.arm.pa.paretrace")
# $2: Mali GPU short name without "Mali-" prefix (default "G72")
# $3: Local gatord binary path (default "gatord")
#
# This script uses the Unix domain socket data channel for gatord, rather
# than than the TCP/IP socket, to avoid issues with permissions on Samsung
# devices. The Streamline GUI must connect to localhost:4242, not the
# automatic adb connection.

APP_NAME=${1:-com.arm.pa.paretrace}
GPU_NAME=${2:-G72}
GATORD_NAME=${3:-gatord}

# Kill old processes and remove old gator components
adb shell pkill gatord
adb shell run-as ${APP_NAME} pkill gatord
adb shell am force-stop ${APP_NAME}
adb shell run-as ${APP_NAME} rm -f /data/data/${APP_NAME}/gatord
adb shell run-as ${APP_NAME} rm -f /data/data/${APP_NAME}/configuration.xml
adb shell rm -f /data/local/tmp/gatord
adb shell rm -f /data/local/tmp/gatord/configuration.xml

# Configure platform and push new gator components
adb shell setprop security.perf_harden 0
adb push ${GATORD_NAME} /data/local/tmp/gatord
adb shell chmod 0777 /data/local/tmp/gatord

# Copy gatord into the application-visible sandbox
adb shell run-as ${APP_NAME} cp /data/local/tmp/gatord /data/data/${APP_NAME}/

# Run gator as the application inside the application-visible sandbox
adb shell run-as ${APP_NAME} /data/data/${APP_NAME}/gatord \
    -M ${GPU_NAME} -p uds --wait-process ${APP_NAME} &

# Run adb forward to tunnel out the device-side UDS to a local TCP port
sleep 1
adb forward tcp:4242 localabstract:streamline-data

# Wait for user to do manual stuff in the Streamline GUI
sleep 1
WAIT_MESSAGE=$'Manual step: Capture in Streamline, and then press any key.\n'
read -n 1 -s -r -p "${WAIT_MESSAGE}"

# Kill old processes and remove old gator components
adb shell pkill gatord
adb shell run-as ${APP_NAME} pkill gatord
adb shell run-as ${APP_NAME} rm /data/data/${APP_NAME}/gatord
adb shell am force-stop ${APP_NAME}
adb shell rm /data/local/tmp/gatord
