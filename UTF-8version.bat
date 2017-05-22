@echo off
setlocal

REM make sure there are enough parameters
if "%~2" == "" exit /b 2

REM set the working directory
pushd "%~2"

REM set the list file
set file="%~1"

REM set the encoding to UTF-8
chcp 65001 >nul

REM loop through the list and create the folders
for /f "delims=" %%G in ('type %file%') do (md "%%~G")

REM restore the working directory and exit
popd
endlocal & exit /b