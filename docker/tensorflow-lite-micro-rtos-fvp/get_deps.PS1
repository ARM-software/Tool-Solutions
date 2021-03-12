# make sure we download into the correct working directory

$BASEDIR=Get-Location

pushd $BASEDIR

echo ""
echo "Downloading ArmCompiler 6.15 and Corstone 300 FVP..."
echo ""

$AC6_exists = Test-Path DS500-BN-00026-r5p0-17rel0.tgz
$FVP_exists = Test-Path FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
$ProgressPreference = 'SilentlyContinue'

if ($AC6_exists -eq $False)
{
	Invoke-WebRequest -Uri https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz -OutFile DS500-BN-00026-r5p0-17rel0.tgz
}
if ($FVP_exists -eq $False)
{
	Invoke-WebRequest -Uri https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz -OutFile FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz
}

popd
