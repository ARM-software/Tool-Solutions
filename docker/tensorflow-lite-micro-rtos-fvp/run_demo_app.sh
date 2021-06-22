#!/bin/bash

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"


# Usage: takes model as input
usage() { 
    echo "Usage: $0 [-f </path/to/fvp>] [-a <path/to/application>]" 1>&2
    echo -e "\e[1;34m   -f|--fvp               \e[m: Pass the path to the FVP to use" 1>&2
    echo -e "\e[1;34m   -a|--application       \e[m: Pass the path to the applicaiton to run" 1>&2
    echo -e "\e[1;34m   -m|--num_macs          \e[m: Ethos-U Configuration for num macs (default: 128)" 1>&2
    echo -e "\e[1;34m   -s|--enable_speed_mode \e[m: Enable speed mode" 1>&2
    echo -e "\e[1;34m   -h|--help              \e[m: Print this message" 1>&2
    exit 1 
}

version_greater_equal()
{
    printf '%s\n%s\n' "$2" "$1" | sort --check=quiet --version-sort
}

DOCKER=""
if grep "docker\|lxc" /proc/1/cgroup >/dev/null 2>&1 ;  
then
    DOCKER="-docker";
fi

BUILDDIR=build${DOCKER}
FVP=FVP_Corstone_SSE-300_Ethos-U55
APPLICATION=$BASEDIR/dependencies/ethos-u/${BUILDDIR}/bin/freertos_person_detection.elf
NUM_MACS=128
SPEED_MODE=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--fvp) FVP="$2"; shift ;;
        -a|--application) APPLICATION="$2"; shift ;;
        -m|--num_macs) NUM_MACS="$2"; shift ;;
        -s|--enable_speed_mode) SPEED_MODE=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

FVP_VERSION=$(command $FVP --version | grep "Fast Models" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/' )

# Check if new or old version of FVP, to know which option to use..
if version_greater_equal "${FVP_VERSION}" 11.13
then
    MAC_CONFIG="-C ethosu.num_macs=$NUM_MACS"
else
    MAC_CONFIG="-C ethosu.config=H$NUM_MACS"
fi

if [ ${SPEED_MODE} -eq 1 ]
then
    if version_greater_equal "${FVP_VERSION}" 11.14
    then
        FAST_MODE='-C ethosu.extra_args="--fast"'
    else
        echo -e "\e[1;31m"
        echo "WARNING: speed mode is only supported on FVP version 11.14 or higher."
        echo "      Using accuracy mode."
        echo -e "\e[m"
    fi
fi

$FVP  \
    --stat \
    -C mps3_board.visualisation.disable-visualisation=1 \
    -C mps3_board.uart0.out_file=- \
    -C mps3_board.telnetterminal0.start_telnet=0 \
    -C mps3_board.uart0.unbuffered_output=1 \
    -C mps3_board.uart0.shutdown_tag="EXITTHESIM" \
    -C cpu0.CFGITCMSZ=15 \
    -C cpu0.CFGDTCMSZ=15 \
    $FAST_MODE \
    $MAC_CONFIG \
    -a $APPLICATION
