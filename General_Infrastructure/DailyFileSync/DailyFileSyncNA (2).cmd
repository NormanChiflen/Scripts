@echo off
REM --- DailyFileSync*.cmd - responsible for copying daily files onto an Expedia e-main web server.
REM Usage: DailyFileSync.cmd - copies daily files from a central file server (default is \\karmalab.net\builds\drops\daily\live) to the local webroot (default is e:\webroot).
REM              To copy daily files from a specific release, add that release name as a parameter; E.g. 'DailyFileSync.cmd R35'

REM -------------------------------------------------------------------------------------
REM ---Globals - leave as default unless you know what you're doing -----
REM -------------------------------------------------------------------------------------
SET FEEDSTORE=KARMALAB.NET\builds
SET FILESYNCLOCATION=\\%FEEDSTORE%\build\FileSync
SET DAILYDROPLOCATION=\\%FEEDSTORE%\drops\daily
SET WEBROOT=e:\webroot
SET RELEASE=%1

REM ---------------------------------------------------------------------
REM -----------MAIN CODE BLOCK-------------------------------
REM ---------------------------------------------------------------------
echo --[INFORMATION]-- SETTING WORKING DIRECTORY
call :setworkingdir
echo --[INFORMATION]-- COPYING FILESYNC.EXE TO WORKING DIRECTORY
call :copyfilesynctoworkingdir
echo --[INFORMATION]-- COPYING MANIFEST FILES TO WORKING DIRECTORY
call :copymanifestfilestoworkingdir

REM Deploy NA-------------------
echo --[INFORMATION]-- SYNCING DAILY FILES
call :copydailyfiles expus %RELEASE%
call :copydailyfiles expca %RELEASE%
call :copydailyfiles expmx %RELEASE%
call :copydailyfiles expbr %RELEASE%
call :copydailyfiles expar %RELEASE%
call :copydailyfiles exprewards %RELEASE%
call :copydailyfiles wwtena %RELEASE%
call :copydailyfiles wwteaarp %RELEASE%
call :copydailyfiles wwteian %RELEASE%
REM /Deploy NA-------------------

echo --[INFORMATION]-- REMOVING WORKING DIRECTORY
call :removefilesyncdir
goto :end



REM ---------------------------------------------------------------------
REM -----------SUB ROUTINES------------------------------------
REM ---------------------------------------------------------------------
:setworkingdir
	if %temp%=="" SET TEMP=c:\temp
	set MYTIME=%time::=%
	set MYTIME=%mytime: =%
	set MYTIME=%mytime:.=%
	set WORKINGDIR=%temp%\FileSync_%MYTIME%
	mkdir %WORKINGDIR%
	goto :eof

:removefilesyncdir
	REM repeat rmdir a few times, as sometimes a race-condition occurs where the dir can't be deleted.
	rmdir /s /q %WORKINGDIR% 2>NUL
	rmdir /s /q %WORKINGDIR% 2>NUL
	rmdir /s /q %WORKINGDIR% 2>NUL
	goto :eof

:copyfilesynctoworkingdir
	robocopy %FILESYNCLOCATION% %WORKINGDIR% FileSync.exe
	goto :eof

:copymanifestfilestoworkingdir
	robocopy %DAILYDROPLOCATION%\live %WORKINGDIR% *.manifest.csv
	goto :eof
	
:copydailyfiles
	%WORKINGDIR%\FileSync.exe -sync -s:%DAILYDROPLOCATION%\live\%1 -t:%WEBROOT%\%1\daily -m:%WORKINGDIR%\%1.manifest.csv -b:M -a:BT
	if not ""=="%RELEASE%" robocopy %DAILYDROPLOCATION%\%RELEASE%\%1 %WEBROOT%\%1\daily *.* /S /E
	goto :eof
	
:end
exit /b