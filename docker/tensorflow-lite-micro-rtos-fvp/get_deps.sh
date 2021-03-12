# make sure we download into the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

echo
echo "Downloading ArmCompiler 6.15 and Corstone 300 FVP..."
echo

# aria2 is faster when downloading big files.
if ! command -v aria2c &> /dev/null
then
    echo
    echo "WARNING: arai2 could not be found we recommend installing aria2 [#> apt-get install aria2] for downloading big files."
    echo "INFO: Downloading using wget instead"
    echo

    [ -f DS500-BN-00026-r5p0-17rel0.tgz ] || wget https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz
    [ -f FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz ] || wget https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
else
    [ -f DS500-BN-00026-r5p0-17rel0.tgz ] || aria2c -x 16 https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz
    [ -f FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz ] || aria2c -x 16 https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
fi

popd