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

SET _CIROOT=\\CHELT2FIL01\ContinuousIntegration\depot\agtexpe\products\mccbin
SET _DBROOT=\\CHELT2FIL01\DirectedBuilds\depot\agtexpe\products\mccbin
SET _RCROOT=\\CHELT2FIL01\ReleaseCandidate\depot\agtexpe\products\mccbin
SET _RELEASEROOT=\\CHELT2FIL01\Release\depot\agtexpe\products\mccbin

SET _PHYLUMROOT=deliverables\depot.agtexpe.products.mccbin

SET _EXECALLPATH=
SET _INSTALLPATH=
SET _ROLE=


:FLIGHTCONTROL
IF EXIST %_CIROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] Continuous Integration Build Found: %_VERSION%
	SET _EXECALLPATH=%_CIROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)

IF EXIST %_DBROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] DirectedBuild Build Found: %_VERSION%
	SET _EXECALLPATH=%_DBROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)


IF EXIST %_RCROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] ReleaseCandidate Build Found: %_VERSION%
	SET _EXECALLPATH=%_RCROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)


IF EXIST %_RELEASEROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] Release Build Found: %_VERSION%
	SET _EXECALLPATH=%_RELEASEROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%
)



:: Server Roles Declarations

:: ---- ProdM APTEPM ----
IF "CHELAIRTVAPM01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAPM02"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- FarmA APTE01 ----
IF "CHELAIRTVA10"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAFA01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

:: ---- FarmB APTE02 ----
IF "CHELAIRTVA32"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAFB01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

:: ---- FarmC APTE03 ----
IF "CHELAIRTVA33"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAFC01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

:: ---- FarmD APTE04 ----
IF "CHELAIRTVA12"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAFD01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

:: ---- FarmE APTE05 ----
IF "CHELAIRTVA55"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAFE01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- FarmF APTE06 ----
IF "CHELAIRTVA66"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELAIRTVAFF01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- FarmG APTE07 ----
IF "CHELAIRTVAFG01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- FarmH APTE08 ----
IF "CHELAIRTVAFH01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- FarmI APTE09 ----
IF "CHELAIRTVAFI01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- FarmJ APTE10 ----
IF "CHELAIRTVAFJ01"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)


:: ---- BFS Accy Farm ----
IF "CHELBFSUTL05"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELBFSUTL06"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELBFSUTL07"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

IF "CHELBFSUTL09"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

:: ---- APTESTR01 Stress Farm ----
IF "CHELAIRTVA88"=="%COMPUTERNAME%" (
	SET _INSTALLPATH="d:\mcclient"
	SET _ROLE="lab"
)

:TAKEOFF
IF ""=="%_EXECALLPATH%" (
	echo [%date% %time%] [ERROR] No Builds found for %_VERSION%
	exit /b 1
)

IF ""=="%_INSTALLPATH%" (
	echo [%date% %time%] [ERROR] No Install Path Specified
	exit /b 1
)

IF ""=="%_ROLE%" (
	echo [%date% %time%] [ERROR] No Deploy Role Specified
	exit /b 1
)

echo [%date% %time%] [INFO] Starting Dumping Environment Variables
echo ******************************************************************************
set
echo ******************************************************************************
echo [%date% %time%] [INFO] Completed Dumping Environment Variables

echo [%date% %time%] [INFO] Deployment Version Specified: %_VERSION%
echo [%date% %time%] [INFO] Deployment Role Specified: %_ROLE%
echo [%date% %time%] [INFO] Calling out %_EXECALLPATH%
echo [%date% %time%] [INFO] Executing MCCBin Deployment...
echo *** START MCCBin Deployment Output *******************************************
%_EXECALLPATH%\mccinstall.bat %_INSTALLPATH% %_ROLE%
SET _MYRETVAL=%ERRORLEVEL%
echo *** END MCCBin Deployment Output *********************************************

echo [%date% %time%] [DEBUG] MCCBin Deployment Completed with the return value of %_MYRETVAL%
IF NOT 0==%_MYRETVAL% echo [%date% %time%] [ERROR] MCCBin Deployment returned the non-zero value of %_MYRETVAL%
exit /b %_MYRETVAL%



:USAGE
::            1         2         3         4         5         6         7         8
::   12345678901234567890123456789012345678901234567890123456789012345678901234567890
echo.
echo This script drives deployment for Multicache Client bits.  End Users supply a
echo desired version to deploy, and this script finds the bits and executes the 
echo correct deployment command.  Roles are hard-coded.  If a target host does not 
echo have a role, please contact the administrators of this script.
echo.
echo %~n0 [Deploy Version] 
echo Example: %~n0 v1.2.0.27 

exit /b 255


endlocal


