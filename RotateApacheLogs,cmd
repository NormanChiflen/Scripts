@echo off

:: Name - svrlogmng.bat
:: Description - Server Log File Manager
::
:: History
:: Date Authory Change
:: 22-May-2005 AGButler Original
:: 14-Jan-2008 AIMackenzie Changed net stops and paths where necessary
:: 16-8-2011 Update to gracefully restart apache and create logs

:: Store where the location of our logs to roll are going to be
set expwebLocation=E:\apps\deploymenthome\expweb5551
set apacheService=expweb5551-httpd
set logLocation=E:\apps\deploymenthome\expweb5551\httpd\logs

:: Store the bin folder for the apache service
set apacheBinRoot=E:\apps\thirdparty\apache-httpd\MSWin64\2.2.22\bin
                
:: ========================================================
:: setup variables and parameters
:: ========================================================
logevent -e 11679 -r "%apacheService% LogRotation" "Starting Apache Log Rotation"

:: generate date and time variables
for /f "tokens=2,3,4 delims=/ " %%i in ('date /T') do set trdt=%%k%%j%%i
for /f "tokens=1,2 delims=: " %%i in ('time /T') do set trtt=%%i%%j
set nftu=%trdt%%trtt%

:: Read Environment from the DeploymentUnit, so we have the correct apache env
for /f "tokens=1,2,3" %%i in ('type %expwebLocation%\deploymentunit.yml') do (
                if "%%j" EQU ":" (
                                set %%i=%%k
                )
)
set expwebDURoot=%expwebLocation%
set apacheDURoot=%expwebLocation%\httpd
set httpdStatusPort=%httpdStatusPort_http%
set httpPort=%httpdPort_http%
set httpsPort=%httpdPort_https%
set ajpPort=%httpdPort_ajp%

:: set the Number Of Archives To Keep
set /a noatk=2

:: ========================================================
:: turn over log files
:: ========================================================

:: change to the apache log file directory
cd %logLocation%

:: Copy files to a new name but the lock will remain. Create the new log files.
for /f "tokens=1 delims= " %%i in ('dir /B %logLocation%\*.log') do (
    move "%logLocation%\%%i" "%logLocation%\%nftu%_%%i" >nul 2>&1

)

:: Restart gracefully which will start writing to new access and error log and remove the file lock.
%apacheBinRoot%\httpd.exe -k restart -n %apacheService%


:: ========================================================
:: zip todays Access and Error log files, then delete old logs
:: ========================================================

:: zip the files
"c:\localbin\zip.exe" -q %logLocation%\%nftu%_logs.zip %logLocation%\%nftu%*.log

:: del the files
del /Q %logLocation%\%nftu%_*.log


:: ========================================================
:: rotate the zip files
:: ========================================================


:: make list of archive zip files
type NUL > %logLocation%\arclist.dat
for /F "tokens=1,2 delims=[] " %%i in ('dir /B %logLocation%\*_logs.zip ^| find /N "_logs.zip"') do echo %%i = %logLocation%\%%j >> %logLocation%\arclist.dat

:: count total number of files
for /F "tokens=1 delims=" %%i in ('type %logLocation%\arclist.dat ^| find /C "_logs.zip"') do set tnof=%%i

:: setup for and create the deletion list
set /a negtk=%noatk%*-1
set /a tntd=%tnof% - %noatk%

type NUL > %logLocation%\dellist.dat
for /L %%i in (%negtk%,1,%tntd%) do find "%%i = " %logLocation%\arclist.dat >> %logLocation%\dellist.dat

:: del the old files
for /F "tokens=3 delims= " %%i in ('find "_logs.zip" %logLocation%\dellist.dat') do del /Q %%i

:: remove temp files
del /Q %logLocation%\arclist.dat
del /Q %logLocation%\dellist.dat
logevent -e 11780 -r "%apacheService% LogRotation" "Apache Log Rotation Complete"
