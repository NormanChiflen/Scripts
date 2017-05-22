
SET SCRIPTPATH=c:\cct_ops\AppFabric\Scripts
SET KEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx

REG ADD %KEY% /V TITLE /D "Restarting AppFabric Configuration" /f
REG ADD %KEY% /v Flags /t REG_DWORD /d "20" /f

REG ADD %KEY%\1003 /VE /D "Powershell" /f
REG ADD %KEY%\1003 /V 101 /D "cmd /c start powershell -nologo -noexit -file %SCRIPTPATH%\SetUpAppFabric-full.ps1 %_AppFabEnv" /f



