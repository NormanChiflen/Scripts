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

SET _CIROOT=\\CHELT2FIL01\ContinuousIntegration\depot\agtexpe\products\air
SET _DBROOT=\\CHELT2FIL01\DirectedBuilds\depot\agtexpe\products\air
SET _RCROOT=\\CHELT2FIL01\ReleaseCandidate\depot\agtexpe\products\air
SET _RELEASEROOT=\\CHELT2FIL01\Release\depot\agtexpe\products\air

SET _PHYLUMROOT=deliverables\depot.agtexpe.products.air

SET _EXECALLPATH=



:FLIGHTCONTROL
IF EXIST %_CIROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] Continuous Integration Build Found: %_VERSION%
	SET _EXECALLPATH=%_CIROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%\prop
)

IF EXIST %_DBROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] DirectedBuild Build Found: %_VERSION%
	SET _EXECALLPATH=%_DBROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%\prop
)


IF EXIST %_RCROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] ReleaseCandidate Build Found: %_VERSION%
	SET _EXECALLPATH=%_RCROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%\prop
)


IF EXIST %_RELEASEROOT%\%_VERSION% (
	echo [%date% %time%] [INFO] Release Build Found: %_VERSION%
	SET _EXECALLPATH=%_RELEASEROOT%\%_VERSION%\%_PHYLUMROOT%\%_VERSION%\prop
)



:: Server Roles Declarations

:: ---- ProdM AIR Farm ----
IF "CHELAIRFDSPM01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS ProdM"
)

IF "CHELAIRTVAPM01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL ProdM"
)

IF "CHELAIRTVAPM02"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL ProdM"
)

IF "CHELAIRTVAPM03"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL ProdM"
)

:: ---- StressA AIR Farm ----
IF "CHELAIRFDSSA01"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY FDS StressA"
)

IF "CHELAIRTVASA01"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY TVA-ALL StressA"
)

IF "CHELAIRTVASA02"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY TVA-ALL StressA"
)

IF "CHELAIRTVASA03"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY TVA-ALL StressA"
)

:: ---- StressB AIR Farm ----
IF "CHELAIRFDSSB01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS StressB"
)

IF "CHELAIRTVASB01"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY TVA-ALL StressB"
)

IF "CHELAIRTVASB02"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY TVA-ALL StressB"
)

IF "CHELAIRTVASB03"=="%COMPUTERNAME%" (
	SET _ROLE="DEPLOY TVA-ALL StressB"
)

:: ---- FarmA APTE01 ----
IF "CHELAIRFDSFA01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmA"
)

IF "CHELAIRTVA10"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmA"
)

IF "CHELAIRTVAFA01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmA"
)

IF "CHELAIRUTLFA01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmA"
)

:: ---- FarmB APTE02 ----
IF "CHELAIRFDSFB01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmB"
)

IF "CHELAIRTVA32"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmB"
)

IF "CHELAIRTVAFB01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmB"
)

IF "CHELAIRUTLFB01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmB"
)

:: ---- FarmC APTE03 ----
IF "CHELAIRFDSFC01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmC"
)

IF "CHELAIRTVA33"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmC"
)

IF "CHELAIRTVAFC01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmC"
)

IF "CHELAIRUTLFC01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmC"
)

:: ---- FarmD APTE04 ----
IF "CHELAIRFDSFD01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmD"
)

IF "CHELAIRFDSFD02"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmD"
)

IF "CHELAIRTVA12"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmD"
)

IF "CHELAIRTVAFD01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmD"
)

IF "CHELAIRUTL12"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmD"
)

IF "CHELAIRUTLFD01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmD"
)

:: ---- FarmE APTE05 ----
IF "CHELAIRFDSFE01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmE"
)

IF "CHELAIRTVA55"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmE"
)

IF "CHELAIRTVAFE01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmE"
)

IF "CHELAIRUTLFE01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmE"
)


:: ---- FarmF APTE06 ----

IF "CHELAIRFDSFF01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FARMF"
)

IF "CHELAIRTVA66"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FARMF"
)

IF "CHELAIRTVAFF01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FARMF"
)

IF "CHELAIRUTLFF01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FARMF"
)


:: ---- FarmG APTE07 ----
IF "CHELAIRFDSFG01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmG"
)

IF "CHELAIRTVAFG01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmG"
)

IF "CHELAIRUTLFG01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy UTL-ALL FarmG"
)

:: ---- FarmH APTE08 ----
IF "CHELAIRFDSFH01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmH"
)

IF "CHELAIRTVAFH01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmH"
)


:: ---- FarmI APTE09 ----
IF "CHELAIRFDSFI01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmI"
)

IF "CHELAIRTVAFI01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmI"
)


:: ---- FarmJ APTE10 ----
IF "CHELAIRFDSFJ01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS FarmJ"
)

IF "CHELAIRTVAFJ01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL FarmJ"
)


:: ---- BFS Accy Farm ----
IF "CHELBFSUTL04"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy FDS BFSUTIL"
)

IF "CHELBFSUTL05"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL BFSUTL05"
)

IF "CHELBFSUTL06"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL BFSUTL06"
)

IF "CHELBFSUTL07"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL BFSUTL07"
)

IF "CHELBFSUTL09"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL BFSUTL09"
)

:: ---- AHPD T2TLS Test Boxes ----
IF "CHELAIRAHPD01"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL BFSUTL06"
)

IF "CHELAIRAHPD02"=="%COMPUTERNAME%" (
	SET _ROLE="Deploy TVA-ALL BFSUTL06"
)


:TAKEOFF
IF ""=="%buildtype%" ( 
	set buildtype=retail
)

IF ""=="%_EXECALLPATH%" (
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
echo [%date% %time%] [INFO] Calling out %_EXECALLPATH%
echo [%date% %time%] [INFO] Executing MTTSetup...
echo *** START MTTSetup Output ****************************************************
%_EXECALLPATH%\setup.exe /f AGTDeploy.ini /u /s %_ROLE%
SET _MYRETVAL=%ERRORLEVEL%
echo *** END MTTSetup Output ******************************************************

echo [%date% %time%] [DEBUG] MTTSetup Completed with the return value of %_MYRETVAL%
IF NOT 0==%_MYRETVAL% echo [%date% %time%] [ERROR] MTTSetup returned the non-zero value of %_MYRETVAL%
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

