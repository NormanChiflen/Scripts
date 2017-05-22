@title Connector Build Script
:: Connector Builds Deployment Script
:: 2011-06-24 - Initial script

:: Assumptions:
:: p4.exe is added to your %PATH%
:: 7z.exe is added to your %PATH%
:: %ANT_HOME% needs to be set
:: %JAVA_HOME% needs to be set

ECHO OFF
SET BLDNUM=%1
SET CONN_LBL=WSE_%BLDNUM%
SET CONN_STAGE_TAR=WSEJava.stage.%CONN_LBL%.tar
SET CONN_PROD_TAR=WSEJava.chaz.prod.%CONN_LBL%.tar
SET CONN_MAINPATH=D:\ConnectorFiles\sait\connector\main
SET BUILDPATH=%CONN_MAINPATH%\Build
SET BUILD_DROP=D:\Connector\Build
SET BUILD_DROP_STAGE=%BUILD_DROP%\STAGE
SET BUILD_DROP_PROD=%BUILD_DROP%\PROD
SET PROD_BUILD=%BUILD_DROP%\PROD\%BLDNUM%
SET STAGEFILE=%CONN_MAINPATH%\WSEJava\Webcore\build\tmp\webApp\stage\WSEJava.war
SET PRODFILE=%CONN_MAINPATH%\WSEJava\Webcore\build\tmp\webApp\prod.chaz\WSEJava.war
SET SHARE_CONN=\\CHELAPPSBX001\Connector\BuildDrops
SET SHARE_CONN_STAGE=%SHARE_CONN%\Staging
SET SHARE_CONN_PROD=%SHARE_CONN%\Prod

@Echo checking variables:
@ECHO.
@ECHO =================================================================================
@ECHO                           Values generated from the script:
@ECHO =================================================================================
@Echo  BLDNUM=%1
@Echo  CONN_LBL=WSE_%BLDNUM%
@Echo  CONN_STAGE_TAR=WSEJava.stage.%CONN_LBL%.tar
@Echo  CONN_PROD_TAR=WSEJava.chaz.prod.%CONN_LBL%.tar
@Echo  CONN_MAINPATH=D:\ConnectorFiles\sait\connector\main
@Echo  BUILDPATH=%CONN_MAINPATH%\Build
@Echo  BUILD_DROP_STAGE=%BUILD_DROP%\STAGE
@Echo  BUILD_DROP_PROD=%BUILD_DROP%\PROD
@Echo  STAGE_BUILD=%BUILD_DROP_STAGE%\%BLDNUM%
@Echo  PROD_BUILD=%BUILD_DROP_PROD%\%BLDNUM%
@Echo  STAGEFILE=%CONN_MAINPATH%\WSEJava\Webcore\build\tmp\webApp\stage\WSEJava.war
@Echo  PRODFILE=%CONN_MAINPATH%\WSEJava\Webcore\build\tmp\webApp\prod.chaz\WSEJava.war
@Echo  SHARE_CONN=\\CHELAPPSBX001\Connector\BuildDrops
@Echo  SHARE_CONN_STAGE=%SHARE_CONN%\Staging
@Echo  SHARE_CONN_PROD=%SHARE_CONN%\Prod
@ECHO.
@ECHO =================================================================================
@ECHO              Values generation from the build environment (system):
@ECHO =================================================================================
@ECHO  JAVA_HOME=%JAVA_HOME%
@ECHO  ANT_HOME=%ANT_HOME%
@ECHO.

if "%JAVA_HOME" EQU "" @echo JAVA_HOME must be defined
if "%ANT_HOME" 	EQU "" @echo JAVA_HOME must be defined



::Pause 1

:: Navigate to Connector Main path
@ECHO Navigating to %CONN_MAINPATH%
cd /d %CONN_MAINPATH%

:: Sync to label
@ECHO =================================================================================
@ECHO              Values generation from the build environment (system):
@ECHO =================================================================================
@ECHO Syncing %CONN_MAINPATH% to %CONN_LBL%
@ECHO Running Command Line:
@ECHO p4 sync ...@%CONN_LBL%
@ECHO DEBUG: We already know this part works, commenting out for now....
p4 sync ...@%CONN_LBL%

:: jump to build path and run ant
@ECHO Building files for %CONN_LBL%
pushd %BUILDPATH%
::start /wait 
@ECHO Running Command Line:
@ECHO call ant -f uberbuild.xml -Drel.num=%BLDNUM% -DdoProduction=true -Dcompile.debug=true build-wse-all
call ant -f uberbuild.xml -Drel.num=%BLDNUM% -DdoProduction=true -Dcompile.debug=true build-wse-all
::Pause 1

:: Copy out stagefile to Build Drop
IF EXIST %STAGEFILE% ( 
    @ECHO Copying %STAGEFILE% to %STAGE_BUILD%\ROOT.war
    pushd %BUILD_DROP_STAGE%
    mkdir %BLDNUM%
    copy /y %STAGEFILE% %STAGE_BUILD%\ROOT.war
  ) ELSE (
  @ECHO ERROR: %STAGEFILE% does not exist!
  @ECHO Process aborting...
  Goto EOF
  )
  
:: Pause 1
 
 :: Copy out prodfile to Build Drop 
 IF EXIST %PRODFILE% ( 
    @ECHO Copying %PRODFILE% to %PROD_BUILD%\ROOT.war
    pushd %BUILD_DROP_PROD%
    mkdir %BLDNUM%
    copy /y %PRODFILE% %PROD_BUILD%\ROOT.war
    ) ELSE (
  @ECHO ERROR: %PRODFILE% does not exist!
  @ECHO Process aborting...
  Goto EOF
  )
  
  ::Pause 1
 
 
 :: Create a staging tar file to deploy
 @ECHO Archiving %STAGE_BUILD%\ROOT.war to %BUILD_DROP%\%CONN_STAGE_TAR%
 ::start /wait 7z a -ttar %BUILD_DROP%\%CONN_STAGE_TAR% %STAGE_BUILD%\ROOT.war 
 call 7z a -ttar %BUILD_DROP%\%CONN_STAGE_TAR% %STAGE_BUILD%\ROOT.war

::Pause 1

 :: Create a pre-prod tar file to deploy
 @ECHO Archviving %PROD_BUILD%\ROOT.war to %BUILD_DROP%\%CONN_PROD_TAR%
 ::start /wait 7z a -ttar %BUILD_DROP%\%CONN_PROD_TAR% %PROD_BUILD%\ROOT.war
call 7z a -ttar %BUILD_DROP%\%CONN_PROD_TAR% %PROD_BUILD%\ROOT.war

::Pause 1

@ECHO Copying file: %CONN_STAGE_TAR%
@ECHO Source: %BUILD_DROP%
@ECHO Destination: %SHARE_CONN_STAGE%
copy /y %BUILD_DROP%\%CONN_STAGE_TAR% %SHARE_CONN_STAGE%
@ECHO.
@ECHO Copying File: %CONN_PROD_TAR%
@ECHO Source: %BUILD_DROP%
@ECHO Destination: %SHARE_CONN_PROD%
copy /y %BUILD_DROP%\%CONN_PROD_TAR% %SHARE_CONN_PROD%
@ECHO.
@ECHO Copying complete. Build script complete!

  
  :EOF