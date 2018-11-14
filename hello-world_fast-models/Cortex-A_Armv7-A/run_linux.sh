#!/bin/bash

# Find subdirectory under 'system' folder, which is the compiler used to generate the virtual platform.
BuildDir=$(ls -d system/* | grep Lin)


# Verify isim_system exists, if it doesn't toss an error
[ ! -f ./$BuildDir/isim_system ] && echo Error, cant find isim_system executable file. Searched directory: ./$BuildDir && exit 0

echo "Running hello world"
./$BuildDir/isim_system -a ./software/hello.axf
