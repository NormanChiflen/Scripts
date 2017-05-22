REM This is a basic build process.

set PROJECT=convoy

if not "%OUTPUT.ROOT%"=="" GOTO outputroot_present
echo "you must have an output.root set in order to use this build.cmd file"
goto END

:outputroot_present

set VERSION=%BUILDSYSTEM_MAJORVERSION%.%BUILDSYSTEM_MINORVERSION%.%BUILDSYSTEM_MAINTENANCEVERSION%
if not "%BUILDSYSTEM_BUILDID%"=="" (
	set VERSION=%VERSION%.%BUILDSYSTEM_BUILDID%
)

if "%%BUILDSYSTEM_MAJORVERSION%%"=="" (
	set VERSION=PRIVATE
)

rmdir /s /q %output.root%\Deliverables\%PROJECT%

mkdir %output.root%\Deliverables\%PROJECT%\%PROJECT%-%VERSION% 

xcopy . %output.root%\Deliverables\%PROJECT%\%PROJECT%-%VERSION%\ /E

echo %VERSION% > %output.root%\Deliverables\%PROJECT%\%PROJECT%-%VERSION%\version.txt

:END