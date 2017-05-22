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

set logLocation=%1

:: Store the bin folder for the apache service
                
:: ========================================================
:: setup variables and parameters
:: ========================================================

:: generate date and time variables
for /f "tokens=2,3,4 delims=/ " %%i in ('date /T') do set trdt=%%k%%j%%i
for /f "tokens=1,2 delims=: " %%i in ('time /T') do set trtt=%%i%%j
set nftu=%trdt%%trtt%


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


:: ========================================================
:: zip todays Access and Error log files, then delete old logs
:: ========================================================

:: del the log files
del /Q %logLocation%\%nftu%_*.log
