# make sure we are building from the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

# TODO: specify which docker image to build?
# {all | fvp, armclang, gcc} should be able to combine, or build all at once.
# default armclang+fvp

# Usage: takes compiler as input
usage() { 
    echo ""
    echo -e "\033[1;33m Usage: \033[0;32m $0\x1b[3m [-c <gcc|armclang>]\x1b[0m" 1>&2
    echo -e "\e[1;33m  Options:" 1>&2
    echo -e "\e[1;36m    -c|--compiler \e[0;36m : Use Arm Compiler (armclang) or gcc to build applications (default: armclang)" 1>&2
    echo -e "\e[m" 1>&2
    popd
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

# Build the docker image for armclang or gcc depending on input argument
if [ $COMPILER = 'armclang' ];
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
        echo "Do you wish to continue building the docker image for Arm Compiler anyways? [y/N]"
        echo -ne "\e[m"

        read yN

        if [ "${yN,,}" = "y" -o "${yN,,}" = "yes" ];
        then
            echo -e "\e[1;33m" 
            echo "INFO: Docker image for Arm Compiler will be built without building example applications"
            echo -e "\e[m"
        else
            echo "INFO: Stopping Docker build"
            popd
            exit;
        fi
    fi

    # get dependencies, then build the armclang docker image 
    ./get_deps.sh -c $COMPILER
    docker build --rm -t tensorflow-lite-micro-rtos-fvp:armclang \
        --build-arg LICENSE_FILE=${ARMLMD_LICENSE_FILE} \
        -f docker/armclang.Dockerfile .
elif [ $COMPILER = 'gcc' ]
then
    ./get_deps.sh -c $COMPILER
    docker build --rm -t tensorflow-lite-micro-rtos-fvp:gcc \
        -f docker/gcc.Dockerfile .
elif [ $COMPILER = 'fvp' ]
then
    # Build docker image for fvp.
    # This image is a minimal evaluation image, that can be used for
    # running built applicaitons with FVP. 
    ./get_deps.sh -c $COMPILER
    docker build --rm -t tensorflow-lite-micro-rtos-fvp:fvp \
        -f docker/fvp.Dockerfile .
else
    usage;
fi


popd
