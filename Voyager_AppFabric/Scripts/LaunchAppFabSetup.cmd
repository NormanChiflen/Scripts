:: LaunchAppFabSetup.cmd
:: 2011-09-22 - Lance Zielinski - initial concept
:: 2011-09-23 - Lance Zielinski - added path logic

@Title Launch AppFabric Setup and Configuration


:: Set Execution POlicy to unRestricted
REG ADD HKLM\Software\Microsoft\Powershell\1\ShellIds\Microsoft.PowerShell /v ExecutionPolicy /t REG_SZ /d Unrestricted /f

IF "%1"=="" GOTO USAGE
IF "%1"=="PROD" GOTO SETPROD
IF "%1"=="LAB" GOTO SETLAB

:SETPROD
SET SCRIPTPATH=\\chc-filidx\cctss\Voyager\AppFabric\Scripts
GOTO LaunchScript

:SETLAB
SET SCRIPTPATH=\\chelappsbx001\public\AppFabric\Scripts
GOTO LaunchScript

:LaunchScript
start cmd /c Powershell.exe -NoLogo -NoExit -File %SCRIPTPATH%\SetUpAppFabric-full.ps1 %1

:USAGE
ECHO.
ECHO USAGE: LaunchAppFabSetup.cmd <ENV>
ECHO.
ECHO ACCEPTED PARAMETERS:
ECHO.
ECHO PROD
ECHO LAB