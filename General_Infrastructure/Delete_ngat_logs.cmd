setlocal enabledelayedexpansion
:: Clean up Log Files older than 5 days. All log files should be consumed by Splunk
::@title Logfile Clean up (source: http://stackoverflow.com/questions/51054/batch-file-to-delete-files-older-than-n-days)
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET LOGFILE="D:\logroot\LogfileCleanup_%dtStamp24%_.log"

set SERVER_LIST=CHELWEBE2ECCT30 CHELWEBE2ECCT31 CHELWEBE2ECCT32 CHELWBANGAT15 CHELWBANGAT16 CHELWBANGAT17 CHELWBANGAT12 CHELWBANGAT13 CHELWBANGAT14 CHELWBANGAT09 CHELWBANGAT10 CHELWBANGAT11

  
for %%i in (%SERVER_LIST%) do (
  net use x: \\%%i\d$
  :: Debug code:: forfiles /p "x:\logroot" /s /m *.* /d "-5" /C "cmd /c echo @path"
  forfiles /p "x:\logroot" /s /m *.* /d "-1" /C "cmd /c del @path"
  net use /d x:
)

goto :end



:end
ECHO Script is ending with %SCRIPTEXIT% >> %LOGFILE%
ECHO. >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%
ECHO    %DATE%-%TIME% - Ending XML copy process with %SCRIPTEXIT% >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%

::Exit 0
endlocal


:: Also I suggest using /c echo @path for testing
:: Note that if you want files OLDER than 10 days, you need to specify -d "-10"