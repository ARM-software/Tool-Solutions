@echo off

rem Parameters
rem ==========
rem %1: Android package name (default "com.arm.pa.paretrace")
rem %2: Mali GPU short name without "Mali-" prefix (default "G72")
rem %3: Local gatord binary path (default "gatord")

rem This script uses the Unix domain socket data channel for gatord, rather
rem than than the TCP/IP socket, to avoid issues with permissions on Samsung
rem devices. The Streamline GUI must connect to localhost:4242, not the
rem automatic adb connection.

set APP_NAME=com.arm.pa.paretrace
if not "%1"=="" set APP_NAME=%1

set GPU_NAME=G72
if not "%2"=="" set GPU_NAME=%2

set GATORD_NAME=gatord
if not "%3"=="" set GATORD_NAME=%3

rem Kill old processes and remove old gator components
adb shell pkill gatord
adb shell run-as %APP_NAME% pkill gatord
adb shell am force-stop %APP_NAME%
adb shell run-as %APP_NAME% rm -f /data/data/%APP_NAME%/gatord
adb shell run-as %APP_NAME% rm -f /data/data/%APP_NAME%/configuration.xml
adb shell rm -f /data/local/tmp/gatord
adb shell rm -f /data/local/tmp/gatord/configuration.xml

rem Configure platform and push new gator components
adb shell setprop security.perf_harden 0
adb push %GATORD_NAME% /data/local/tmp/gatord
adb shell chmod 0777 /data/local/tmp/gatord

rem Copy gatord into the application-visible sandbox
adb shell run-as %APP_NAME% cp /data/local/tmp/gatord /data/data/%APP_NAME%/

rem Run gator as the application inside the application-visible sandbox
rem Note the <NUL is needed to avoid start stealing the input from the parent
start /b adb shell run-as %APP_NAME% /data/data/%APP_NAME%/gatord ^
    -M %GPU_NAME% -p uds --wait-process %APP_NAME% < NUL

rem Run adb forward to tunnel out the device-side UDS to a local TCP port
timeout 1 /nobreak > NUL
adb forward tcp:4242 localabstract:streamline-data

rem Wait for user to do manual stuff in the Streamline GUI
timeout 1 /nobreak > NUL
echo Manual step: Capture in Streamline, and then press any key.
pause

rem Kill old processes and remove old gator components
adb shell pkill gatord
adb shell run-as %APP_NAME% pkill gatord
adb shell run-as %APP_NAME% rm /data/data/%APP_NAME%/gatord
adb shell am force-stop %APP_NAME%
adb shell rm /data/local/tmp/gatord
