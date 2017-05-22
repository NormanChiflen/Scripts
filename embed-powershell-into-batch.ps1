#Second, we take it a step further and create a polyglot script to embed the entire ps1 file into the batch file.  This is great for distributing a single file and not having to worry about the launcher (the .cmd file) being separated from the ps1 file, or someone trying to run the ps1 file directly, or opening it in the ISE.


@@echo off
:CheckPowerShellExecutionPolicy
@@FOR /F "tokens=*" %%i IN ('powershell -noprofile -command Get-ExecutionPolicy') DO Set PSExecMode=%%i
@@if /I "%PSExecMode%"=="unrestricted" goto :RunPowerShellScript
@@if /I "%PSExecMode%"=="remotesigned" goto :RunPowerShellScript
 
@@NET FILE 1>NUL 2>NUL
@@if not "%ERRORLEVEL%"=="0" (
@@echo Elevation required to change PowerShell execution policy from [%PSExecMode%] to RemoteSigned
@@powershell -NoProfile -Command "start-process -Wait -Verb 'RunAs' -FilePath 'powershell.exe' -ArgumentList '-NoProfile Set-ExecutionPolicy RemoteSigned'"
@@) else (
@@powershell -NoProfile Set-ExecutionPolicy RemoteSigned
@@)
 
:RunPowerShellScript
@@set POWERSHELL_BAT_ARGS=%*
@@if defined POWERSHELL_BAT_ARGS set POWERSHELL_BAT_ARGS=%POWERSHELL_BAT_ARGS:"=\"%
@@PowerShell -Command Invoke-Expression $('$args=@(^&amp;{$args} %POWERSHELL_BAT_ARGS%);'+[String]::Join([Environment]::NewLine,$((Get-Content '%~f0') -notmatch '^^@@^|^^:'))) &amp; goto :EOF
 
{ 
	# Start PowerShell
	write-host -ForegroundColor Yellow "hello"
	# End PowerShell
}.Invoke($args)
#In order for the polyglot script to work, we exclude all lines in the file which begin with @@ (two at symbols) or : (a semi-colon).  Neither @@ or : are normally used in PowerShell on the beginning of the line (whitespace counts), so it’s generally (but not always) safe to do this.  Anything else in the file will be treated as PowerShell.  A script block is used to invoke the script such that param() can remain valid, and accept parameters passed into the batch file.
