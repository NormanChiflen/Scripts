setlocal enabledelayedexpansion
:: The goal of this script is to centralize all logs for backup/restore purposes

SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET LOGFILE="d:\logroot\VoyagerLogCleanUP\VoyagerLogCleanUP_%dtStamp24%_.log"
if not exist d:\logroot\VoyagerLogCleanUP md d:\logroot\VoyagerLogCleanUP

set QA=CHELWEBCRM79 CHELWEBCRM80 CHELWBANGAT04 CHELWBANGAT05

set TRAINING=CHEXWBANGTTA001 CHEXWBANGTTA002 CHEXWBANGTTB001 CHEXWBANGTTB002
set ISOPROD=CHEXWBANGTIP001
set PROD=CHEXWBANGT001 CHEXWBANGT002 CHEXWBANGT003 CHEXWBANGT004 CHEXWBANGT005 CHEXWBANGT006
set SERVER_LIST=%TRAINING% %ISOPROD% %PROD%

:: If in the lab, run the QA servers
if /i "%computername%" EQU "chelappsbx001" set SERVER_LIST=%QA%
  
call :start

for %%i in (%SERVER_LIST%) do (
	if not exist d:\logroot\voyager\%%i\voyager 			md d:\logroot\voyager\%%i\voyager
	if not exist d:\logroot\voyager\%%i\ApplicationEvent 	md d:\logroot\voyager\%%i\ApplicationEvent
	if not exist d:\logroot\voyager\%%i\iis 				md d:\logroot\voyager\%%i\iis
	
	if exist \\%%i\logroot\voyager (
		robocopy \\%%i\logroot\voyager d:\logroot\voyager\%%i\ *.log /E
		for /f "skip=3" %%j in ('dir /s /a:-d /b /o:-d \\%%i\logroot\voyager\*.log') do del %%j >>%LOGFILE%
		for /f "skip=30" %%j in ('dir /s /a:-d /b /o:-d d:\logroot\voyager\*.log') do del %%j >>%LOGFILE%
	)
  
	if exist \\%%i\c$\windows\system32\winevt\logs (
		robocopy \\%%i\c$\windows\system32\winevt\logs d:\logroot\ApplicationEvent\%%i\ app*.evtx /E
		for /f "skip=3" %%j in ('dir /s /a:-d /b /o:-d \\%%i\c$\windows\system32\winevt\logs\app*.evtx') do del %%j >>%LOGFILE%
		for /f "skip=30" %%j in ('dir /s /a:-d /b /o:-d d:\logroot\ApplicationEvent\app*.evtx') do del %%j >>%LOGFILE%
	)  
	
	if exist \\%%i\c$\inetpub\logs\LogFiles\ (
		robocopy \\%%i\c$\inetpub\logs\LogFiles\ d:\logroot\iis\%%i\ *.log /E
		for /f "skip=3" %%j in ('dir /s /a:-d /b /o:-d \\%%i\c$\inetpub\logs\LogFiles\*.log') do del %%j >>%LOGFILE%
		for /f "skip=30" %%j in ('dir /s /a:-d /b /o:-d d:\inetpub\logs\LogFiles\*.log') do del %%j >>%LOGFILE%
	)  
)

goto :end


:start
ECHO. >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%
ECHO    %DATE%-%TIME% - Starting Archived Event Log Cleanup process  >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%
goto :eof

:end
ECHO. >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%
ECHO    %DATE%-%TIME% - Ending Archived Event Log Cleanup process  >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%

::Exit 0
endlocal




