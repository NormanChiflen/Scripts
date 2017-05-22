@echo off
path=C:\Perl\bin\;C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;C:\MICROSOFT SITE SERVER\BIN;C:\CRS30\BIN;C:\Program Files\Microsoft SQL Server\80\Tools\BINN;C:\Program Files\SecureCRT\;C:\PROGRA~1\SecureFX;C:\ResKit\;C:\PROGRA~1\CA\Common\SCANEN~1;C:\PROGRA~1\CA\eTrust\ANTIVI~1;c:\devtools


@REM ####*---Declarations---*#
for /f "eol= tokens=1,2* delims=\" %%i in ('whoami.exe') do set username=%%j
for /f "eol= tokens=1,2,3,4,5* delims=^^/ " %%i in ("%date%") do set datetime=%%j-%%k-%%l
@REM for /f "eol= tokens=1,* delims=" %i in ('dir /b \\dnrdc02\c$\markus') do set filename=%i
set logfile=scripter.txt
set srcdir=\\dnfil01\ops\scripts\releasescripts\ONE-OFF-SCRIPTS\fds
set file1=NTRIGHTS_DnwbmamrCAxx_Even.cmd
set file2=NTRIGHTS_DnwbmamrCAxx_odd.cmd
set file3=NTRIGHTS_DNWBMAMRCTxx_EVEN.cmd
set file4=NTRIGHTS_DNWBMAMRCTxx_ODD.cmd
set file5=NTRIGHTS_DNWBMAMRNCxx_EVEN.cmd
set file6=NTRIGHTS_DNWBMAMRNCxx_ODD.cmd
set file7=NTRIGHTS_DNWBMAMRUSxx_EVEN.cmd
set file8=NTRIGHTS_DNWBMAMRUSxx_ODD.cmd


@REM ####*---protection---*#
choice /c:123456789 /T:8,15 "choose 1-8"
echo %errorlevel%
IF {%errorlevel%}=={1} goto DnwbmamrCAxx_Even
IF {%errorlevel%}=={2} goto DnwbmamrCAxx_odd
IF {%errorlevel%}=={3} goto DNWBMAMRCTxx_EVEN
IF {%errorlevel%}=={4} goto DNWBMAMRCTxx_ODD
IF {%errorlevel%}=={5} goto DNWBMAMRNCxx_EVEN
IF {%errorlevel%}=={6} goto DNWBMAMRNCxx_ODD
IF {%errorlevel%}=={7} goto DNWBMAMRUSxx_EVEN
IF {%errorlevel%}=={8} goto DNWBMAMRUSxx_ODD
IF {%errorlevel%}=={9} goto syntax




@REM #choice  /tn,15 "%username%, this will update Sherpa, odd followed by even. Are you sure you want to do @REM #this?">\\dnrdc02\c$\markus\%logfile%

@REM #*---Body---*#


goto eof
:syntax
cls
3echo Syntax:
echo parameter - = hotfix folder (hotfix date) --> now automatic
echo parameter - = username (no domain) --> now automatic
echo parameter 1 = password
echo help = this screen
echo For example:
echo sherpa_hotfix_script_scriptable.cmd %datetime% %username% Fu008@r3d 
pause

:eof