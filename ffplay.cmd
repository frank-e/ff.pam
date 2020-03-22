@echo off & @rem based on XNT.kex script template version 2016-03-05
setlocal enableextensions & prompt @
if     "%~1" == ""     goto HELP & @rem expect one argument
if     "%~1" == "?"    goto HELP & @rem missing switch char
if     "%~1" == "/?"   goto HELP & @rem minimal requirement
if     "%~1" == "-?"   goto HELP & @rem permit DOS SWITCHAR
if     exist "%~1\*"   goto HELP & @rem bypass subdirectory
:DOIT --------------------------------------------------------------
set NEED=ffplay.exe
for %%x in (%NEED%) do if not exist "%%~f$PATH:x" goto NEED
set EXEC=ansicon.exe -m %NEED%
set OPTS=ansicon.exe
for %%x in (%OPTS%) do if     exist "%%~f$PATH:x" goto OPTS
set EXEC=%NEED%
set AV_LOG_FORCE_NOCOLOR=1
:OPTS --------------------------------------------------------------
set SDL_AUDIODRIVER=directsound
set OPTS=-hide_banner
echo %EXEC% %OPTS% %* 1>&2
%EXEC% %OPTS% %* 1>&2
if not errorlevel 1     goto WAIT
echo Error: %0 got exit code [%ERRORLEVEL%]
goto WAIT
:NEED --------------------------------------------------------------
echo/
echo Error: %0 found no "%NEED%"
:HELP --------------------------------------------------------------
echo Usage: %0 ARGS
echo/
echo This script uses ffplay.exe (as found in the PATH)
echo to display a file given in ARGS after temporarily
echo setting SDL_AUDIODRIVER=directsound
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
