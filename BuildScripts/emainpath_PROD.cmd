@echo off
REM #########################################################
REM This script execute the vbscript to update the system path to include %systemdrive%\ExpediaSys

REM Log all changes
REM Action 	xxxx-xx-xx username change description

REM Created 	2008-07-10 johnmca New script for X64 build out

REM #########################################################

setlocal
echo ------%DATE%------%TIME%----------- >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
echo Updating the System Path >> c:\temp\%COMPUTERNAME%_SERVERBUILD.txt

%windir%\system32\cscript.exe \\chc-filidx\glappeng\jegilbert\BuildScripts\emainpath.vbs


if %ERRORLEVEL% EQU 111 goto updated
if %ERRORLEVEL% EQU 112 goto noupdate

if %ERRORLEVEL% NEQ 0 goto error111

:error111
if %ERRORLEVEL% NEQ 111 goto error112

:error112
if %ERRORLEVEL% NEQ 112 goto error


echo SUCCESS >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
REM %windir%\notepad c:\temp\%COMPUTERNAME%_SERVERBUILD.txt
goto eof

:updated
echo System path was updated successfully. A reboot is required. >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
REM %windir%\notepad c:\temp\%COMPUTERNAME%_SERVERBUILD.txt
goto eof


:noupdate
echo No change needed. >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
REM %windir%\notepad c:\temp\%COMPUTERNAME%_SERVERBUILD.txt
goto eof


:error
echo Failed to Update System Path Environment Variable
echo Failed to Update System Path Environment Variable >> %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
%systemdrive%\localbin\sleep 3
%windir%\notepad %systemdrive%\temp\%COMPUTERNAME%_SERVERBUILD.txt
exit

:eof

