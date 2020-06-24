@echo off
rem 
rem build.bat - Build the SystemC Peripheral example.
rem 
rem Copyright 2012-2020 ARM Limited.
rem All rights reserved.
rem 

IF %VisualStudioVersion%==15.0 ( nmake /nologo /f nMakefile rel_vs141_64 
goto END )
IF %VisualStudioVersion%==14.0 ( nmake /nologo /f nMakefile rel_vs14_64 
goto END )  
echo "no valid Visual Studio version. have you installed and/or configured VS 2015 or 2017?"
: END
