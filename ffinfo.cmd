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
set NEED=ffprobe.exe
for %%x in (%NEED%) do if not exist "%%~f$PATH:x" goto NEED
set EXEC=ansicon.exe -m %NEED%
set OPTS=ansicon.exe
for %%x in (%OPTS%) do if     exist "%%~f$PATH:x" goto OPTS
set EXEC=%NEED%
set AV_LOG_FORCE_NOCOLOR=1
:OPTS --------------------------------------------------------------
set OPTS=-err_detect crccheck+bitstream+buffer+careful+aggressive
set EXEC=%EXEC% -hide_banner %OPTS% -xerror -v warning
set NEED=%~1
if not exist "%NEED%"  goto NEED
set OPTS=-show_entries format=format_name,duration,tags:error
set OPTS=%OPTS%:stream=codec_type,codec_name,duration,sample_fmt
set OPTS=%OPTS%,sample_rate,channels,channel_layout,pix_fmt
set OPTS=%OPTS%,width,height,bit_rate,r_frame_rate
set OPTS=%OPTS%,sample_aspect_ratio,display_aspect_ratio
set OPTS=%OPTS% -of csv=p=0:svr=? -unit -sexagesimal
set EXEC=%EXEC% %OPTS% -strict experimental -probesize 2MiB "%NEED%"
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
echo This script uses ffprobe.exe (as found in the PATH)
echo to show the codec(s), container format, and duration
echo of a media FILE in a "pretty compact" format.
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
