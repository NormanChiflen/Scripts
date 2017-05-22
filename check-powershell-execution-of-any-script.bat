#http://www.daveamenta.com/2013-03/embed-powershell-inside-a-batch-file/
#the only thing batch files are useful for is bootstrapping PowerShell scripts.  Below are two different ways to launch a PowerShell script from a batch file.
 
#First, we use a small batch file to check that the PowerShell execution policy is suitable for our script (i.e. either RemoteSigned or Unrestricted).  If the policy is suitable, we continue to the script.  If it isn’t, we prompt to elevate, change the policy, then continue on to execute the script.


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
powershell -noprofile "%~dp0MY_SCRIPT_IN_THE_SAME_DIRECTORY.ps1 %1"