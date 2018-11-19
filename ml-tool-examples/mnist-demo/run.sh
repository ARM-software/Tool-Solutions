#!/bin/bash

# Simple script to run with a few different options. 

# When launching from Streamline it's easier to run a script than typing
# the commands into the Streamline dialog box

export LD_LIBRARY_PATH=/home/arm01/armnn-devenv/armnn/build/ 

# export MALI_TIMELINE_ENABLE=1
# export MALI_TIMELINE_PROFILING_ENABLED=1  
# MALI_FRAMEBUFFER_DUMP_ENABLED=1 
# MALI_SW_COUNTERS_ENABLED=1

if [ "$#" -eq 1 ]; then
    # Set the type of acceleration 1=CPU and 2=GPU
    echo "running ./mnist_tf_convol $1 1999"
    ./mnist_tf_convol $1  1999
elif [ "$#" -eq 0 ]; then
    # Default case just runs CPU accellerated
    echo "defaulting to CPU acclerated"
    echo "running ./mnist_tf_convol 1 1999"
    ./mnist_tf_convol 1 1999
else 
    # Control type of acceleration and iterations by just forwarding command line
    echo "running ./mnist_tf_convol $*"
    ./mnist_tf_convol $*
fi

