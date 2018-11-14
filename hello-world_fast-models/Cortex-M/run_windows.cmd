@echo off

:: Find subdirectory under 'system' folder, which is the compiler used to generate the virtual platform.
set cmd="dir system /a:d /b | findstr Win"
FOR /F "tokens=*" %%i IN (' %cmd% ') DO SET BuildDir=%%i

:: Verify isim_system exists, if it doesn't toss an error
if not exist .\system\%BuildDir%\isim_system_%BuildDir%.exe echo Error, cant find the isim_system executable file. Searched directory ".\system\%BuildDir%\". Exiting && EXIT /B

echo "Running hello world"
.\system\%BuildDir%\isim_system_%BuildDir%.exe -a .\software\hello.axf
