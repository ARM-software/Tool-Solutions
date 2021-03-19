# make sure we download into the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

# Usage: takes compiler as input
usage() { 
    echo "Usage: $0 [-c <gcc|armclang>]" 1>&2
    echo "   -c|--compiler      : gcc|armclang" 1>&2
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

# aria2 is faster when downloading big files.
if [ $COMPILER = 'armclang' ]
then
    echo
    echo "Downloading ArmCompiler 6.15 and Corstone 300 FVP..."
    echo

    [ -f DS500-BN-00026-r5p0-17rel0.tgz ] || wget https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz
    [ -f FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz ] || wget https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
elif [ $COMPILER = 'gcc' ]
then
    echo
    echo "Downloading GNU GCC and Corstone 300 FVP..."
    echo

    [ -f gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 ] || wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
    [ -f FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz ] || wget https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
elif [ $COMPILER = 'fvp' ]
then
    echo
    echo "Downloading Corstone 300 FVP..."
    echo
    [ -f FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz ] || wget https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
else
    usage;
fi

popd
