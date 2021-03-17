# make sure we are building from the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR


# Usage: takes compiler as input
usage() { 
    echo "Usage: $0 [-c <gcc|armclang>]" 1>&2
    echo "   -c|--compiler      : gcc|armclang (default: armclang)" 1>&2
    popd
    exit 1 
}

COMPILER=armclang
NPROC=`grep -c ^processor /proc/cpuinfo`

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--compiler) COMPILER="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

if [ $COMPILER = 'armclang' ];
then
    ./get_deps.sh -c armclang
    docker build --rm -t ubuntu:18.04_sse300 \
        --build-arg ARMLMD_LICENSE_FILE=$ARMLMD_LICENSE_FILE \
        -f docker/armclang.Dockerfile \
        .
elif [ $COMPILER = 'gcc' ]
then
    ./get_deps.sh -c gcc
    docker build --rm -t ubuntu:18.04_sse300 \
        -f docker/gcc.Dockerfile \
        .
else
    usage;
fi

popd