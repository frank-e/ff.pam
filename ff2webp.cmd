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
set DEST=%~dpn1.webp
if not exist "%NEED%"   goto NEED
if /I "%~x1" == ".WEBP" goto DEST
set SWSF=-sws_flags accurate_rnd+bitexact+full_chroma_inp
set SWSF=%SWSF%+full_chroma_int+spline
rem -lossless 1 is not VP8 and can only handle 32bits RGBA (bgra)
rem -lossless 0 is RIFF WEBPVP8 and can handle yuv420p / yuva420p
rem -preset 0..5 enforces lossy, i.e., ignores -lossless 1
rem -preset -1..5: none default picture photo drawing icon text
rem (photo is "outdoor", picture is "portrait", default is TBD)
set FLTV=-filter:v format=bgra
set OPTS=-c:v libwebp -lossless 1
set FLTV=-filter:v noformat=bgra
set OPTS=-c:v libwebp -preset picture
set OPTS=%OPTS% -quality 100 -compression_level 6
set EXEC=%EXEC% -i "%NEED%" -an %SWSF% %FLTV% %OPTS% "%DEST%"
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
echo for a conversion of a single picture in any format
echo supported by FFmpeg to a lossy -preset picture WEBP.
echo/
:WAIT if first CMD line option was /c ------------------------------
set NEED=usebackq tokens=2 delims=/
for /F "%NEED% " %%c in ('%CMDCMDLINE%') do if /I "%%c" == "c" pause
:DONE -------------- (Frank Ellermann, 2016) -----------------------
