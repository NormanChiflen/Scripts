@echo off
REM ------------------------------------
REM --------MTTSetup Parameters---------
rem https://confluence/display/EMEAETG/Emain+and+E3+deployment+on+EMEA+lab+servers
REM ------------------------------------
set buildtype=retail
set branch=MAIN
set inifile=ewe.bgb.ini
set inisection=WEBALL
REM ------------------------------------
 
call :setworkingdir
echo STOPPING SERVICES...
call :stopservices
REM if the server is a WEB server, run WebSiteMaker.vbs to create all sites on it
echo %COMPUTERNAME% | find /I /V "WEB" || echo CREATING WEBSITES... && call :runwebsitemaker
echo RUNNING MTTSETUP... (this could take anywhere from 5-60 minutes)
call :runmttsetup
 
REM sometimes MTTSetup blindly quits due to a weird race condition. Check for those error codes, and restart mttsetup if found.
if /i %errorlevel%==-1073741819 call :runmttsetup
if /i %errorlevel%==-128 call :runmttsetup
 
if %errorlevel%==0 (
echo MTTSETUP COMPLETED SUCCESSFULLY
echo LOG: %WORKINGDIR%\MTTSetup.log
) else (
echo ERROR: MTTSETUP FAILED! RETURNCODE=%errorlevel%
echo.
echo LOG: %WORKINGDIR%\MTTSetup.log
echo -----------------------------ERROR SNIPPET-------------------------------------
tail -25 %WORKINGDIR%\MTTSetup.log | findstr /i "fail error"
echo -------------------------------------------------------------------------------
)
 
goto :end
 
REM ----------------------------------------------
REM ------------------- SUBROUTINES---------------
REM ----------------------------------------------
:setworkingdir
if %temp%=="" SET TEMP=c:\temp
set MYTIME=%time::=%
set MYTIME=%mytime: =%
set MYTIME=%mytime:.=%
set WORKINGDIR=%temp%\PROP_EMAIN_%MYTIME%
mkdir %WORKINGDIR%
goto :eof
 
:stopservices
kill -f mstravob *sp fds* w3svc ablog gralog *bot mmc.exe spoof.exe > %WORKINGDIR%\KillServices.log
kill -f mstravob *sp fds* w3svc ablog gralog *bot mmc.exe spoof.exe >> %WORKINGDIR%\KillServices.log
kill -f mstravob *sp fds* w3svc ablog gralog *bot mmc.exe spoof.exe >> %WORKINGDIR%\KillServices.log
net session /delete /y >> %WORKINGDIR%\KillServices.log
goto :eof
 
:runwebsitemaker
cscript \\karmalab.net\builds\buildtools\WebSiteMaker.vbs /createall /ssl > %WORKINGDIR%\WebSiteMaker.log
goto :eof
 
:runmttsetup
REM make sure c:\expediasys is in the path.
echo %PATH% | find /I "%SYSTEMDRIVE%\expediasys" > nul || set path=%SYSTEMDRIVE%\expediasys;%PATH%
IF NOT "%inisection%"=="" SET section="/S: %inisection%"
cscript \\chelfilrtt01\build\callmttsetup.vbs /B:%branch% /I:%inifile% %section% > %WORKINGDIR%\MTTSetup.log
goto :eof
 
:end
echo.
echo.
pause