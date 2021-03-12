
# make sure we are building from the correct working directory
$BASEDIR = Get-Location

pushd $BASEDIR

.\get_deps.PS1

docker build --rm -t ubuntu:18.04_sse300 --file .\docker\Dockerfile --build-arg "ARMLMD_LICENSE_FILE=$env:ARMLMD_LICENSE_FILE" .

popd
