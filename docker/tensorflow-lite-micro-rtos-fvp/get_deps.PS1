param ($compiler='armclang')
# make sure we download into the correct working directory

$BASEDIR=Get-Location

pushd $BASEDIR

$AC6_exists = Test-Path DS500-BN-00026-r5p0-17rel0.tgz
$GCC_exists = Test-Path gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
$FVP_exists = Test-Path FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
$ProgressPreference = 'SilentlyContinue'

if($compiler -eq "armclang")
{
	Write-Output ""
	Write-Output "Downloading ArmCompiler 6.15 and Corstone 300 FVP..."
	Write-Output ""
	
	if ($AC6_exists -eq $False)
	{
		Invoke-WebRequest -Uri https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz -OutFile DS500-BN-00026-r5p0-17rel0.tgz
	}
}
elseif($compiler -eq "gcc")
{
	Write-Output ""
	Write-Output "Downloading GNU GCC and Corstone 300 FVP..."
	Write-Output ""
	
	if ($GCC_exists -eq $False)
	{
		Invoke-WebRequest -Uri https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 -OutFile gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
	}
}
else
{
	Write-Warning "
Usage: ./get_deps.PS1 -compiler <armclang|gcc> 
  -compiler: Choose to use ArmCompiler or GCC <armclang|gcc> (default: armclang)
"
	popd
	exit
}

if ($FVP_exists -eq $False)
{
	Invoke-WebRequest -Uri https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz -OutFile FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
}

popd
