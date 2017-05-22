setlocal enabledelayedexpansion
:: NoSale xfer script
::@title EndCall Transfer Script
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET LOGFILE="d:\logroot\EventLogCleanUP\EventLogCleanUP_%dtStamp24%_.log"
if not exist d:\logroot\EventLogCleanUP md d:\logroot\EventLogCleanUP
set SERVER_LIST=CHELWBANGAT01 CHELWEBCRM77 CHELWBANGAT03 CHELWEBCRM07 CHELWBANGAT18 CHELWBANGAT12 CHELWBANGAT13 CHELWBANGAT14 CHELWBANGAT15 CHELWBANGAT16 CHELWBANGAT17 CHELWEBE2ECCT30 CHELWEBE2ECCT31 CHELWEBE2ECCT32 CHELWBANGAT09 CHELWBANGAT10 CHELWBANGAT11 CHELWEBCRM79 CHELWEBCRM80 CHELWEBCRM82 CHELWBANGAT04 CHELWBANGAT05 CHELWBANGAT06 CHELWBANGAT07

set SRCPATH="\\%%i\c$\Windows\System32\winevt\Logs"
  
call :start

for %%i in (%SERVER_LIST%) do (
	if exist \\%%i\c$\Windows\System32\winevt\Logs\Archive-Application* (
		for /f "skip=5" %%j in ('dir /s /b /o:-d \\%%i\c$\Windows\System32\winevt\Logs\Archive-Application*') do del %%j >>%LOGFILE%
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




