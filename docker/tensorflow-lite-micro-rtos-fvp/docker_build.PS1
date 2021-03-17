param ($compiler='armclang')
# make sure we are building from the correct working directory
$BASEDIR = Get-Location

pushd $BASEDIR

if( $compiler -eq 'armclang' )
{    
    .\get_deps.PS1 -compiler $compiler
    docker build --rm -t ubuntu:18.04_sse300 --file .\docker\armclang.Dockerfile --build-arg "ARMLMD_LICENSE_FILE=$env:ARMLMD_LICENSE_FILE" .
}
elseif( $compiler -eq 'gcc' )
{
    .\get_deps.PS1 -compiler $compiler
    docker build --rm -t ubuntu:18.04_sse300 --file .\docker\gcc.Dockerfile .
}
else
{
    echo ""
    echo "Usage: ./docker_build.PS1 -compiler <armclang|gcc>"
    echo "  compiler: Choose to use ArmCompiler of GCC <armclang|gcc> (default: armclang)"
    echo ""
}

popd