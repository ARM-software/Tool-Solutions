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
    .\scripts\get_deps.PS1 -compiler $compiler
    docker build --rm -t tensorflow-lite-micro-rtos-fvp:armclang --file .\docker\armclang.Dockerfile .
}
elseif( $compiler -eq 'gcc' )
{
    .\scripts\get_deps.PS1 -compiler $compiler
    docker build --rm -t tensorflow-lite-micro-rtos-fvp:gcc --file .\docker\gcc.Dockerfile .
}
elseif( $compiler -eq 'fvp' )
{
    # Build docker image for fvp.
    # This image is a minimal evaluation image, that can be used for
    # running built applicaitons with FVP. 
    .\scripts\get_deps.PS1 -compiler $compiler
    docker build --rm -t tensorflow-lite-micro-rtos-fvp:fvp --file .\docker\fvp.Dockerfile .
}
else
{
    Write-Warning "
Usage: ./docker_build.PS1 -compiler <armclang|gcc>
  -compiler: Choose to use ArmCompiler or GCC <armclang|gcc> (default: armclang)
"
    exit
}

popd
