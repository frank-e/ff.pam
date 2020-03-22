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
rem http://trac.ffmpeg.org/wiki/vpxEncodingGuide
rem http://www.webmproject.org/docs/encoder-parameters/
set OPTS=-quality best -deadline best -auto-alt-ref 1
set OPTS=%OPTS% -cpu-used 0 -profile:v 1 -b:v 250KiB
set OPTS=%EXEC% -i "%NEED%" %SWSF% %FLTV% -c:v libvpx %OPTS%
set EXEC=%OPTS% -pass 1 -an -y nul.webm
echo %EXEC% 1>&2
%EXEC%
if     errorlevel 1    goto LOGS
set EXEC=%OPTS% -pass 2 -c:a libvorbis -b:a 25KiB "%DEST%"
echo %EXEC% 1>&2
%EXEC%
:LOGS --------------------------------------------------------------
if     errorlevel 1    echo ERROR: %0 got exit code [%ERRORLEVEL%]
if     exist  %LOGS%   del %LOGS%
goto WAIT
:JFTR --------------------------------------------------------------
rem q:a = b:a/64 +4 for b:a 256..512K with q:a 8..12
rem q:a = b:a/32    for b:a 128..256K with q:a 4..8
rem q:a = b:a/16 -4 for b:a  64..128K with q:a 0..4
rem q:a 8.224 = b:a 270336 = 33*1024*8 = 33 KiB = 264 Ki (~270 kbps)
rem q:a 7.168 = b:a 229376 = 28*1024*8 = 28 KiB = 224 Ki (~229 kbps)
rem q:a 6.4   = b:a 204800 = 25*1024*8 = 25 KiB = 200 Ki (~205 kbps)
rem q:a 6.144 = b:a 196608 = 24*1024*8 = 24 KiB = 196 Ki (~197 kbps)
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
echo to create video VP8, audio vorbis, format WebM in
echo two passes (libvpx quality good, deadline best.)
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
