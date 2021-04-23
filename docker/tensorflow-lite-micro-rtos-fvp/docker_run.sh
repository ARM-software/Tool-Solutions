#!/bin/bash

# Usage: select docker image
usage() { 
    echo "Usage: $0 [-c <gcc|armclang>]" 1>&2
    echo "   -i|--image     : The docker image to run, gcc|armclang (default: armclang)" 1>&2
    echo "   -c|--command   : The command to run inside the docker image, within quotes (optional)" 1>&2
    exit 1 
}

COMPILER=armclang
COMMAND=/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--image) COMPILER="$2"; shift ;;
        -c|--command) COMMAND="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

pushd ${BASEDIR}
mkdir -p dependencies

if [ $COMPILER == 'armclang' ];
then
    if [ -z ${ARMLMD_LICENSE_FILE} ]; 
    then 
        echo -e "\e[1;31m" 
        echo "WARNING: ARMLMD_LICENSE_FILE is unset"
        echo -e "\e[0;33m"
        echo "You need to set the ARMLMD_LICENSE_FILE environment variable to" 
        echo "point at a valid License in order to use the Arm Compiler (armclang)"
        echo "If you don't have a valid license, you can request a 30 day evaluation license at (https://developer.arm.com/support)."
        echo "Alternatively you can use the GNU gcc docker image instead (use the --help argument to see usage options)."
        echo ""
        echo "Do you wish to continue running the docker image for Arm Compiler anyways? [y/N]"
        echo -ne "\e[m"

        read yN

        if [ "${yN,,}" = "y" -o "${yN,,}" = "yes" ];
        then
            echo -e "\e[1;33m" 
            echo "INFO: Docker image for Arm Compiler will run, you won't be able to build any samples before setting the ARMLMD_LICENSE_FILE variable manually"
            echo -e "\e[m"
        else
            echo "INFO: Aborting..."
            popd
            exit;
        fi
    fi
fi

# TODO: using shared work directory between host and container
docker run \
    -v $PWD/sw:/work/sw \
    -v $PWD/dependencies:/work/dependencies \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -e DISPLAY=unix$DISPLAY \
    -e LOCAL_USER_ID=$(id -u) \
    -e ARMLMD_LICENSE_FILE=$ARMLMD_LICENSE_FILE \
    -e ARM_TOOL_VARIANT=$ARM_TOOL_VARIANT \
    --network host -it --rm tensorflow-lite-micro-rtos-fvp:$COMPILER $COMMAND

popd
