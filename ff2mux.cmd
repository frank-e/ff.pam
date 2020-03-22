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
set DEST=%~dpn1.mp4
set NEED=%~dpn1.flv
set OPTS=
if /I "%~x1" == ".FLV" goto TEST
set NEED=%~dpn1.mov
if /I "%~x1" == ".MOV" goto TEST
set NEED=%~dpn1.avi
rem allow to mux AVC+MP3 for AVI
set OPTS=-strict -1
if /I "%~x1" == ".AVI" goto TEST
set OPTS=
set NEED=%~dpn1.m4a
if not exist "%NEED%"  goto NEED
set EXEC=%EXEC% -i "%NEED%"
set NEED=%~dpn1.m4v
if /I "%~x1" == ".M4V" goto TEST
if /I "%~x1" == ".M4A" goto TEST
goto DEST
:TEST --------------------------------------------------------------
if not exist "%NEED%"  goto NEED
if /I "%~x1" == ".MP4" goto DEST
if     exist "%DEST%"  del /P "%DEST%"
if     exist "%DEST%"  goto DEST
set EXEC=%EXEC% -i "%NEED%" %OPTS% -c copy "%DEST%"
echo %EXEC% 1>&2
%EXEC%
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
echo to mux FILE.m4a (audio) and FILE.m4v (dash video)
echo in FILE.mp4 (mpeg-4) copying audio and video as is.
echo/
echo Alternatively FILE.flv, FILE.mov, or FILE.avi can
echo be muxed into FILE.mp4 copying audio and video as
echo far as the input codecs are permitted in FILE.mp4
echo (newer FLV, QT, or VIDX might work.)
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
