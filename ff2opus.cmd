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
set NEED=ffmpeg.exe
for %%x in (%NEED%) do if not exist "%%~f$PATH:x" goto NEED
set EXEC=ansicon.exe -m %NEED%
set OPTS=ansicon.exe
for %%x in (%OPTS%) do if     exist "%%~f$PATH:x" goto OPTS
set EXEC=%NEED%
set AV_LOG_FORCE_NOCOLOR=1
:OPTS --------------------------------------------------------------
set OPTS=-err_detect crccheck+bitstream+buffer+careful+aggressive
set EXEC=%EXEC% -hide_banner %OPTS% -xerror -v verbose
set NEED=%~1
if not exist "%NEED%"  goto NEED
set DEST=%~dpn1.opus
if /I "%~x1" == ".OPUS" goto DEST
if     exist "%DEST%"  del /P "%DEST%"
if     exist "%DEST%"  goto DEST
set FLTA=aresample=48000:resampler=soxr:precision=28:ocl=downmix
set FLTA=-filter:a %FLTA%:cheby=1:matrix_encoding=dolby:tsf=s32p
set OPTS=-c:a libopus -mapping_family 255 -b:a 25KiB
set EXEC=%EXEC% -i "%NEED%" -vn %FLTA% %OPTS% "%DEST%"
echo %EXEC% 1>&2
%EXEC%
if     errorlevel 1    echo ERROR: %0 got exit code [%ERRORLEVEL%]
goto WAIT
:DEST --------------------------------------------------------------
echo/
echo Error: %0 cannot create "%DEST%"
goto WAIT
:NEED --------------------------------------------------------------
echo/
echo Error: %0 found no "%NEED%"
:HELP --------------------------------------------------------------
echo Usage: %0 FILE
echo/
echo This script uses ffmpeg.exe (as found in the PATH)
echo to encode an audio track with OPUS (video ignored).
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
