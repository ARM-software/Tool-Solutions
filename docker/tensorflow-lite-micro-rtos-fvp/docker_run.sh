#!/bin/bash

# Usage: takes compiler as input
usage() { 
    echo "Usage: $0 [-c <gcc|armclang>]" 1>&2
    echo "   -c|--compiler  : The docker image to run, gcc|armclang (default: armclang)" 1>&2
    exit 1 
}

COMPILER=armclang

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--compiler) COMPILER="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# make sure we are building from the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

docker run -it --rm tensorflow-lite-micro-rtos-fvp:$COMPILER

popd
