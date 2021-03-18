param ($compiler='armclang')

# make sure we are building from the correct working directory
$BASEDIR = Get-Location

pushd $BASEDIR

if( $compiler -eq 'armclang' )
{    
    if([string]::IsNullOrEmpty($env:ARMLMD_LICENSE_FILE))
    {
        Write-Output ""
        Write-Warning "ARMLMD_LICENSE_FILE environment variable is not defined
        
You need to set the ARMLMD_LICENSE_FILE environment variable to
point at a valid License in order to use the Arm Compiler (armclang)
If you don't have a valid license, you can request a 30 day evaluation license at (https://developer.arm.com/support).
Alternatively you can use the GNU gcc docker image instead (use the --help argument to see usage options).

Do you wish to continue building the docker image for Arm Compiler anyways? [y/N]"
        $yN = Read-Host

        if($yN -eq "y" -Or $yN -eq "Y")
        {
            Write-Output "INFO: Docker image for Arm Compiler will be built without building example applications"
        }
        else
        {
            Write-Output "INFO: Stopping Docker build"
            popd
            exit;
        }
    }
    .\get_deps.PS1 -compiler $compiler
    docker build --rm -t ubuntu:18.04_sse300 --file .\docker\armclang.Dockerfile --build-arg "LICENSE_FILE=$env:ARMLMD_LICENSE_FILE" .
}
elseif( $compiler -eq 'gcc' )
{
    .\get_deps.PS1 -compiler $compiler
    docker build --rm -t ubuntu:18.04_sse300 --file .\docker\gcc.Dockerfile .
}
else
{
    Write-Output ""
    Write-Output "Usage: ./docker_build.PS1 -compiler <armclang|gcc>"
    Write-Output "  -compiler: Choose to use ArmCompiler of GCC <armclang|gcc> (default: armclang)"
    Write-Output ""
    exit
}

# Build docker image for fvp.
# This image is a minimal evaluation image, that can be used for
# running built applicaitons with FVP. 
docker build --rm -t tflm_corstone300:fvp --file .\docker\fvp.Dockerfile .

popd