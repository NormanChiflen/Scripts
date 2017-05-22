rem http://devio.wordpress.com/2012/02/16/test-if-network-directory-exists-in-batch-file-cmd/

rem Test if Network Directory exists in Batch file (.cmd)
rem The default way to check whether a directory exists in a Windows batch file (.cmd) is


if not exist "%directory%\nul" (
   echo %directory% does not exist
)However, as this MS KB explains, the check for the NUL file does not work with directories on network drives mapped to a drive letter.

A working solution I found is to process the ERRORLEVEL value a DIR command sets

dir %directory% >nul 2>nul
if errorlevel 1 (
   echo %directory does not exist
)or

dir %directory% >nul 2>nul
if not errorlevel 1 (
    echo %directory exists
)

http://devio.wordpress.com/2012/02/16/test-if-directory-exists-in-batch-file-cmd/

http://devio.wordpress.com/2012/02/16/test-if-network-directory-exists-in-batch-file-cmd/
REM the result if a check with IF EXIST depend on whether

REM the drive is a local drive or a mapped network drive or a UNC path 
REM the path contains spaces or not 
REM the path is quoted or not 
REM cmd runs in administrator mode or user mode 
REM I wrote a small batch file that contains a couple of assignments of the form

set dir=c:\temp
set dir=c:\temp\with spaces
etc.and executed these tests on each value

if exist %dir% echo exists
if exist %dir%\nul echo exists
if exist %dir%\. echo exists
if exist "%dir%" echo exists
if exist "%dir%\nul" echo exists
if exist "%dir%\." echo exists



