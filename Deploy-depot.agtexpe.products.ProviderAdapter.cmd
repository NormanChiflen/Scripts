@ECHO OFF

setlocal
:PREFLIGHT

rem echo DEBUG
rem echo p1: %1
rem echo p2: %2
rem echo p3: %3
rem echo p4: %4
rem echo p5: %5
rem echo p6: %6
rem echo p7: %7
rem echo p8: %8
rem echo p9: %9

SET _VERSION=%1
:: Obsolete call-in of Role... this is overriden below by hard-set roles for 
:: hostnames
rem SET _ROLE=%2
rem SET _ROLE=%_ROLE:"=%

IF ""=="%_VERSION%" (
	echo [%date% %time%] [ERROR] No Deploy Version Specified
	GOTO USAGE
)
rem IF ""=="%_ROLE%" (
rem 	echo [%date% %time%] [ERROR] No Deploy Role Specified
rem 	GOTO USAGE
rem )

SET _CIROOT=\\CHELT2FIL01\ContinuousIntegration\depot\agtexpe\products\provideradapter
SET _DBROOT=\\CHELT2FIL01\DirectedBuilds\depot\agtexpe\products\provideradapter
SET _RCROOT=\\CHELT2FIL01\ReleaseCandidate\depot\agtexpe\products\provideradapter
SET _RELEASEROOT=\\CHELT2FIL01\Release\depot\agtexpe\products\provideradapter

SET _PHYLUMROOT=deliverables\depot.agtexpe.products.provideradapter

SET _SRCDEPDIR=

SET _IISUSERNAME=karmalab\_travfusesvc
SET _IISPASSWORD=TravelFusion!10

:FLIGHTCONTROL
IF EXIST %_CIROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] Continuous Integration Build Found: %_VERSION%
	SET _SRCDEPDIR=%_CIROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)

IF EXIST %_DBROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] DirectedBuild Build Found: %_VERSION%
	SET _SRCDEPDIR=%_DBROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)


IF EXIST %_RCROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] ReleaseCandidate Build Found: %_VERSION%
	SET _SRCDEPDIR=%_RCROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)


IF EXIST %_RELEASEROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] Release Build Found: %_VERSION%
	SET _SRCDEPDIR=%_RELEASEROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)



:: Server Roles Declarations

:: ---- PAD Farm A ----
IF "CHELAIRPADFB01"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish

	rem You could override the user and password here....
	rem SET _IISUSERNAME=karmalab\_MySvcAcct
	rem SET _IISPASSWORD=P@ssw0rd
)

:: ---- PAD Farm G ----
IF "CHELAIRPADFG01"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish
)

:: ---- PAD Prod M ----
IF "CHELAIRPADPM01"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish
)

:: ---- PAD Stress B ----
IF "CHELAIRPADSB01"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish
)

IF "CHELAIRPADSB02"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish
)

:: ---- PAD Prod Stable ----
IF "CHELAIRPADPS01"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish
)

IF "CHELAIRPADPS02"=="%COMPUTERNAME%" (
	SET _DEPTYPE=Release
	SET _DESTDIR=E:\TravelFusionWebSvcIISPublish
)


:TAKEOFF
IF ""=="%_DESTDIR%" ( 
	set _DESTDIR=E:\TravelFusionWebSvcIISPublish
)

IF ""=="%_DEPTYPE" (
	SET _DEPTYPE=Release
)

IF ""=="%_SRCDEPDIR%" (
	echo [%date% %time%] [ERROR] No Builds found for %_VERSION%
	exit /b 1
)
echo [%date% %time%] [INFO] Starting Dumping Environment Variables
echo ******************************************************************************
set
echo ******************************************************************************
echo [%date% %time%] [INFO] Completed Dumping Environment Variables

echo [%date% %time%] [INFO] Deployment Version Specified: %_VERSION%
echo [%date% %time%] [INFO] Deployment Role Specified: %_ROLE%
echo [%date% %time%] [INFO] Calling out %_SRCDEPDIR%

echo [%date% %time%] [INFO] Stopping IIS

net stop w3svc

:: Check for previous install and move it
if exist %_DESTDIR% (
	echo [%date% %time%] [INFO] Executing IISSvc.bat -uninstall
	cd /d %_DESTDIR%\bin
	call iissvc.bat -uninstall
	if exist %_DESTDIR%.old (
		echo [%date% %time%] [INFO] Removing the old .old
		rd /s /q %_DESTDIR%.old
		echo [%date% %time%] [INFO] Removing the old .old returned %ERRORLEVEL%
	)

	echo [%date% %time%] [INFO] moving %_DESTDIR% to %_DESTDIR%.old
	move %_DESTDIR% %_DESTDIR%.old
	echo [%date% %time%] [INFO] moving returned %ERRORLEVEL%
)

echo [%date% %time%] [INFO] Executing Robocopy... Pulling in files

robocopy %_SRCDEPDIR%\%_DEPTYPE%\TravelFusionWebSvcIISPublish %_DESTDIR% *.* /S /E /NP /W:1 /R:3

echo [%date% %time%] [INFO] Executing IISSvc.bat 
echo *** START Deployment Output **************************************************

pushd %_DESTDIR%\bin

cd /d %_DESTDIR%\bin
call iissvc.bat -install /iis7.applicationpool.processmodel.UserName=%_IISUSERNAME% /iis7.applicationpool.processmodel.password=%_IISPASSWORD% /IIS7.ApplicationPool.ProcessModel.MaxProcesses=4 /AppCfg.AppLogDir=e:\TravFuseLogs
SET _MYRETVAL=%ERRORLEVEL%

echo [%date% %time%] [DEBUG] isssvc.bat Completed with the return value of %_MYRETVAL%

popd

echo *** END Deployment Output ****************************************************

echo [%date% %time%] [INFO] Starting IIS

net start w3svc

echo [%date% %time%] [DEBUG] Deployment Completed with the return value of %_MYRETVAL%
IF NOT 0==%_MYRETVAL% echo [%date% %time%] [ERROR] Deployment returned the non-zero value of %_MYRETVAL%
exit /b %_MYRETVAL%



:USAGE
::            1         2         3         4         5         6         7         8
::   12345678901234567890123456789012345678901234567890123456789012345678901234567890
echo.
echo This script drives deployment for Air Interface systems.  End Users supply a
echo desired version to deploy and the deployment role, and this script finds the
echo bits and executes the correct deployment command.  Roles are hard-coded.  If a
echo target host does not have a role, please contact the administrators of this
echo script.
echo.
echo %~n0 [Deploy Version] 
echo Example: %~n0 v1.2.0.27 

exit /b 255


endlocal

