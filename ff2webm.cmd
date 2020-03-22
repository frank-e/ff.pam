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
set DEST=ffmpeg2pass-?.*
if     exist  %DEST%   del /P  %DEST%
if     exist  %DEST%   goto DEST
set LOGS=%DEST%
set DEST=%~dpn1.webm
if /I "%~x1" == ".WEBM" goto DEST
if     exist "%DEST%"  del /P "%DEST%"
if     exist "%DEST%"  goto DEST
set SWSF=-sws_flags accurate_rnd+bitexact+full_chroma_inp
set SWSF=%SWSF%+full_chroma_int+spline
set FLTV=smartblur=1:-0.1:11
set FLTV=-filter:v %FLTV%,hqdn3d=3:2:3,pp=ac/al,format=yuv422p
rem http://wiki.webmproject.org/ffmpeg/vp9-encoding-guide
rem http://trac.ffmpeg.org/wiki/Encode/VP9
rem http://developers.google.com/media/vp9/settings/vod/
set OPTS=-auto-alt-ref 1 -lag-in-frames 25 -b:v 250KiB -crf 20
set OPTS=%EXEC% -i "%NEED%" %SWSF% %FLTV% -c:v vp9 %OPTS%
set EXEC=%OPTS% -pass 1 -an -y nul.webm
echo %EXEC% 1>&2
%EXEC%
if     errorlevel 1    goto LOGS
set FLTA=aresample=48000:resampler=soxr:precision=28:ocl=downmix
set FLTA=-filter:a %OPUS%:cheby=1:matrix_encoding=dolby:tsf=s32p
set OPUS=-c:a libopus -mapping_family 255 -b:a 25KiB
set EXEC=%OPTS% -pass 2 %FLTA% %OPUS% "%DEST%"
echo %EXEC% 1>&2
%EXEC%
:LOGS --------------------------------------------------------------
if     errorlevel 1    echo ERROR: %0 got exit code [%ERRORLEVEL%]
if     exist  %LOGS%   del %LOGS%
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
echo to create video VP9, audio OPUS, format WebM in
echo two passes (libvpx quality good, deadline best.)
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
