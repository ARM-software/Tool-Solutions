#!/bin/bash

# TODO: select which docker image to run?
# better way to run the docker containers efficiently.
# Run the docker image commands through the run script?
# if docker exists, run in docker, if not run local? 
# maybe not too smart, dum is better?

# ./run_demo_app.sh --docker <true|false> --app <app name> ...

# make sure we are building from the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

docker run --user $(id -u):$(id -g) -v sw:/work/sw -it --rm tflm_corstone300:fvp 

popd
