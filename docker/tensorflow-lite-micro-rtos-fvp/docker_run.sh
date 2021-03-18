#!/bin/bash

# make sure we are building from the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

docker run -it --rm ubuntu:18.04_sse300 

popd
