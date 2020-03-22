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
if not exist "%NEED%"   goto NEED
set DEST=%~dpn1.sld
if     exist "%DEST%\*" rd /S "%DEST%"
if     exist "%DEST%\*" goto DEST
if not exist "%DEST%\*" md "%DEST%"
if not exist "%DEST%\*" goto DEST
set SWSF=-sws_flags accurate_rnd+bitexact+full_chroma_inp
set SWSF=%SWSF%+full_chroma_int+spline
set DEST=%DEST%\%~n1%%05d.png
set FLTV=thumbnail=30,smartblur=1:-0.1:11
set FLTV=-filter:v %FLTV%,hqdn3d=3:2:3,pp=ac/al,format=rgb24
set OPTS=-f image2 -c:v png -r 1 -dpi 96
set EXEC=%EXEC% -i "%NEED%" %SWSF% %FLTV% -an %OPTS% "%DEST%"
echo %EXEC% 1>&2
%EXEC%
if not errorlevel 1     goto WAIT
echo Error: %0 got exit code [%ERRORLEVEL%]
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
echo to create a temporary folder with PNGs of video FILE
echo at a rate of one frame per second.
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
