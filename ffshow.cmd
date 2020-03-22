@echo off & @rem based on XNT.kex script template version 2016-03-05
setlocal enableextensions & prompt @
if not "%~2" == ""     call "%~0" "%*"
if not "%~2" == ""     goto DONE & @rem expect one argument
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
set OPTS=-err_detect crccheck+bitstream+buffer+careful+aggressive
set EXEC=%EXEC% -hide_banner %OPTS% -v verbose
set NEED=%~1
if not exist "%NEED%"   goto NEED
set EXEC=%EXEC% -vf cropdetect,scale=nhd
set EXEC=%EXEC% -af volumedetect,replaygain "%NEED%" -autoexit
echo %EXEC% 1>&2
%EXEC%
if not errorlevel 1     goto WAIT
echo Error: %0 got exit code [%ERRORLEVEL%]
goto WAIT
:NEED --------------------------------------------------------------
echo/
echo Error: %0 found no "%NEED%"
:HELP --------------------------------------------------------------
echo Usage: %0 FILE
echo/
echo This script uses ffplay.exe (as found in the PATH)
echo to detect the cropping in a given video FILE.
echo Press "Q" to quit when the crop=W:H:X:Y is clear,
echo then use ffmpeg -i FILE -vf crop=W:H:X:Y OUTPUT
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
