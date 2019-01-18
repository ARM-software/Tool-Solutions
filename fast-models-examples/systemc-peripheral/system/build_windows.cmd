@echo off

:: Run this file in the 'VS2015 x64 Native Tools Command Prompt'
:: This will ensure building for a 64-bit simulation.

nmake /nologo /f nMakefile rel_vs14_64
