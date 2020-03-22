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
set DEST=%~dpn1.mp4
if /I "%~x1" == ".MP4" goto DEST
if     exist "%DEST%"  del /P "%DEST%"
if     exist "%DEST%"  goto DEST
set SWSF=-sws_flags accurate_rnd+bitexact+full_chroma_inp
set SWSF=%SWSF%+full_chroma_int+spline
set FLTV=smartblur=1:-0.1:11
set FLTV=-filter:v %FLTV%,hqdn3d=3:2:3,pp=ac/al,format=yuv422p
rem http://trac.ffmpeg.org/wiki/Encode/H.264
set OPTS=-profile:v high444 -preset slow -me_method esa -me_range 24
set OPTS=%OPTS% -refs 6 -bf 4 -rc-lookahead 60 -trellis 2 -subq 10
set OPTS=%OPTS% -nr 100 -tune film  -threads 1 -b:v 250KiB
set OPTS=%EXEC% -i "%NEED%" %SWSF% %FLTV% -c:v libx264 %OPTS%
set EXEC=%OPTS% -pass 1 -an -y nul.mp4
echo %EXEC% 1>&2
%EXEC%
if     errorlevel 1    goto LOGS
set FLTA=aresample=48000:resampler=soxr:precision=28:ocl=stereo
set FLTA=-filter:a %FLTA%:cheby=1:matrix_encoding=dolby:tsf=s32p
set LAME=-c:a libmp3lame -compression_level 9 -abr 1 -b:a 25KiB
set EXEC=%OPTS% -pass 2 -movflags +faststart %FLTA% %LAME% "%DEST%"
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
echo to convert video to H.264 libx264 and audio to MP3.
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
