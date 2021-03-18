#!/bin/bash

BASEDIR=$(dirname "$0")


# Usage: takes model as input
usage() { 
    echo "Usage: $0 [-f </path/to/fvp>] [-a <path/to/application>]" 1>&2
    echo "   -f|--fvp      : pass the absolute path to the FVP" 1>&2
    echo "   -a|--application   : pass the path to the applicaiton to run" 1>&2
    echo "   -m|--num_macs      : Ethos-U Configuration for num macs (default: 128)" 1>&2
    echo "   -h|--help          : Print this message" 1>&2
    exit 1 
}

FVP=FVP_Corstone_SSE-300_Ethos-U55
APPLICATION=$BASEDIR/sw/corstone-300-mobilenet-v2/build/ethosu55-mobilenet-v2.elf
NUM_MACS=128

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--fvp) FVP="$2"; shift ;;
        -a|--application) APPLICATION="$2"; shift ;;
        -m|--num_macs) NUM_MACS="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if new or old version of FVP, to know which option to use..
if command $FVP --version | grep 11.13.41 &> /dev/null
then
    MAC_CONFIG="-C ethosu.num_macs=$NUM_MACS"
else
    MAC_CONFIG="-C ethosu.config=H$NUM_MACS"
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
    $MAC_CONFIG \
    -a $APPLICATION
