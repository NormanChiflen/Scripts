@echo off
path=C:\Perl\bin\;C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;c:\devtools

IF {%1}=={} goto syntax
IF {%2}=={} goto syntax
IF {%1}=={help} goto syntax
IF {%1}=={/?} goto syntax 
IF {%1}=={-?} goto syntax

@REM Environmental data
for /f "eol= tokens=1,2* delims= " %%i in ('C:\markus\hcomscripts\who_ami.cmd') do set username=%%k
for /f "eol= tokens=1,2,3,4,5* delims=^^/ " %%i in ("%date%") do set datetime=%%j-%%k-%%l
for /f "eol= tokens=1,2* delims=[]" %%i in ('nslookup %2') do set serverip=%%i
for /f "eol= tokens=1,2* delims=:" %%i in ("%serverip%") do set serverip=%%j
set logging= \\dnrdc02\c$\markus\cruisebounce.tmp
set output=\\dnfil01\e$\ops\Scripts\ReleaseScripts\ONE-OFF-SCRIPTS\cruise\Output\cruisebounce.txt
@REM main
echo %2 was restarted at: %date%%time%,  %username% restarted it >> %logging%
echo %2 was restarted at: %date%%time%,  %username% restarted it > %output%
sleep 2
psexec \\%2 -u expeso\%username% -p %1 net stop CruiseListener
cls
psexec \\%2 -u expeso\%username% -p %1 net stop Cruiseapi|grep -i stopped
sleep 2
cls
psexec \\%2 -u expeso\%username% -p %1 kill cruiseapi|grep -i stopped
sleep 2
cls
psexec \\%2 -u expeso\%username% -p %1 kill CruiseListener|grep -i stopped
sleep 2
cls
psexec \\%2 -u expeso\%username% -p %1 kill portserv |grep -i stopped
sleep 2
cls
sclist \\%2 |grep -i Cruise
sclist \\%2 |grep -i Cruise >> %output% 
choice /c:12 /tn,30 "%username%, Are cruise Services now stopped (1 no, 2, yes)?
IF {%errorlevel%}=={1} goto rerun
IF {%errorlevel%}=={2} goto restart

@REM Restart Sub
:restart
cls
psexec \\%2 -u expeso\%username% -p %1 net start cruiseapi
sleep 2
cls
psexec \\%2 -u expeso\%username% -p %1 net start CruiseListener
sleep 2
cls
psexec \\%2 -u expeso\%username% -p %1 net start CruisePortMapper
sleep 2
cls
sclist \\%2 |grep -i Cruise
sclist \\%2 |grep -i Cruise >> %output% 
choice /c:12 /tn,30 "%username%, Are cruise Services now started (1 no, 2, yes)?
IF {%errorlevel%}=={1} goto restart
IF {%errorlevel%}=={2} goto testscript

@REM Retry to kill services sub
:rerun
cls
pskill \\%2 -u expeso\%username% -p %1 cruiseapi
sleep 2
cls
pskill \\%2 -u expeso\%username% -p %1 CruiseListener
sleep 2
cls
pskill \\%2 -u expeso\%username% -p %1 portserv
sleep 2
cls
sclist \\%2 |grep -i Cruise
sclist \\%2 |grep -i Cruise >> %output% 
choice /c:12 /tn,30 "%username%, Are cruise Services now stopped (1 no, 2, yes)?
IF {%errorlevel%}=={1} goto rerun
IF {%errorlevel%}=={2} goto restart

@REM test fatclient.
:testscript
cls
\\dnutlsbr01\Cruise_Monitoring_share\CruiseSocketClient.exe %serverip% 7566 \\%2\Cruise_Monitoring_share\SailAvail.xml \\dnmon05\c$\SiteScope\htdocs\%2_SailAvailadhoc_resp.xml 

start \\dnmon05\c$\SiteScope\htdocs\%2_SailAvailadhoc_resp.xml
goto eof


:syntax
cls
echo Syntax:

	echo parameter 1 = password
	echo parameter 2 = server name
	echo help = this screen
	echo For example:
	echo sherpa_hotfix_script_scriptable.cmd Fu008@r3d dnutlsbr01 
	echo location of the log file %output%
	pause
:eof