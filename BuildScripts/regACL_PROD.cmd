@echo off
REM #########################################################
REM This script uses reg.exe and setacl.exe to update HKLM\Software\Expedia registry permissions

REM Log all changes
REM Action 	xxxx-xx-xx username change description

REM Created 	2008-07-10 johnmca New script for X64 build out

REM #########################################################

setlocal
echo ------%DATE%------%TIME%----------- >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
echo Update hklm\software\expedia permissions >> c:\temp\%COMPUTERNAME%_SERVERBUILD.txt

%systemdrive%\localbin\reg.exe query hklm\software\expedia /ve

if %ERRORLEVEL% EQU 0 goto update
if %ERRORLEVEL% EQU 1 goto create

:create
%systemdrive%\localbin\reg add \\%COMPUTERNAME%\hklm\software\expedia
echo Expedia Reg key created Successfully >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
goto update


:update
%systemdrive%\localbin\SetACL.exe -on "hklm\software\expedia" -ot reg -actn ace -ace "n:expeso\_ablog;p:full"
if %ERRORLEVEL% NEQ 0 goto error

%systemdrive%\localbin\SetACL.exe -on "hklm\software\expedia" -ot reg -actn ace -ace "n:expeso\_gralog;p:full"
if %ERRORLEVEL% NEQ 0 goto error

echo Updated Expedia key permissions >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt

goto eof

:error
echo Failed to create\update Expedia registry key
echo Failed to create\update Expedia registry key >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
%windir%\notepad %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
exit

:eof



