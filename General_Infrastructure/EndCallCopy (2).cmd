setlocal enabledelayedexpansion
:: NoSale xfer script
::@title EndCall Transfer Script
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET LOGFILE="D:\logroot\EndCall\EndCallXMLCopy_%dtStamp24%_.log"

set SERVER_LIST=CHELWEBE2ECCT30 CHELWEBE2ECCT31 CHELWEBE2ECCT32 CHELWBANGAT15 CHELWBANGAT16 CHELWBANGAT17 CHELWBANGAT12 CHELWBANGAT13 CHELWBANGAT14 CHELWBANGAT09 CHELWBANGAT10 CHELWBANGAT11

  ::set SRCFILES="\\%%i\e$\ngat\endcall"
  ::set DSTFILES="\\chelappsbx001\NGAT_Builds\EndCallDrop\%%i"
  
for %%i in (%SERVER_LIST%) do (
  if not exist \\chelappsbx001\NGAT_Builds\EndCallDrop\%%i\imported md D:\NGAT_Builds\EndCallDrop\%%i\imported
  if not exist \\chelappsbx001\NGAT_Builds\EndCallDrop\%%i\failed md D:\NGAT_Builds\EndCallDrop\%%i\failed
  robocopy "\\%%i\e$\ngat\endcall\drop" "D:\NGAT_Builds\EndCallDrop\%%i" /e /r:3 /w:5 2>&1 >>%LOGFILE%
  for /f "skip=1" %%j in ('dir /b /o:-d \\%%i\e$\ngat\endcall\drop') do del \\%%i\e$\ngat\endcall\drop\%%j
  
)

goto :end


:FolderCleanup
ECHO.
ECHO Cleaning up %SRCFILES% >> %LOGFILE%
del /F /q %SRCFILES%\* >> %LOGFILE% && goto end

:end
ECHO Script is ending with %SCRIPTEXIT% >> %LOGFILE%
ECHO. >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%
ECHO    %DATE%-%TIME% - Ending XML copy process with %SCRIPTEXIT% >> %LOGFILE%
ECHO ===================================================================== >> %LOGFILE%

::Exit 0
endlocal