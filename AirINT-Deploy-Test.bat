REM Norman Fletcher
REM bootstrapping PowerShell scripts
REM check PowerShell execution policy(i.e. either RemoteSigned or Unrestricted).  If policy is unsuitable elevate (might require -force), change the policy, then continue on to execute the script.


@echo off
:CheckPowerShellExecutionPolicy
FOR /F "tokens=*" %%i IN ('powershell -noprofile -command Get-ExecutionPolicy') DO Set PSExecMode=%%i
if /I "%PSExecMode%"=="unrestricted" goto :RunPowerShellScript
if /I "%PSExecMode%"=="remotesigned" goto :RunPowerShellScript
 
NET FILE 1>NUL 2>NUL
if not "%ERRORLEVEL%"=="0" (
	echo Elevation required to change PowerShell execution policy from [%PSExecMode%] to RemoteSigned
	powershell -NoProfile -Command "start-process -Wait -Verb 'RunAs' -FilePath 'powershell.exe' -ArgumentList '-NoProfile Set-ExecutionPolicy RemoteSigned'"
) else (
	powershell -NoProfile Set-ExecutionPolicy RemoteSigned
)
 

 
:RunPowerShellScript
rem powershell -noprofile "%~dp0MY_SCRIPT_IN_THE_SAME_DIRECTORY.ps1 %1"

rem powershell write-host -ForegroundColor Yellow "running powershell script"
powershell -noprofile "%~dp0%1"



pause