# make sure we are building from the correct working directory
BASEDIR=$(dirname "$0")
pushd $BASEDIR

./get_deps.sh

docker build --rm -t ubuntu:18.04_sse300 \
    --build-arg ARMLMD_LICENSE_FILE=$ARMLMD_LICENSE_FILE \
    -f docker/Dockerfile \
    .

popd