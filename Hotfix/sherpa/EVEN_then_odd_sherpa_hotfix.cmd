@echo off
path=C:\Perl\bin\;C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;C:\MICROSOFT SITE SERVER\BIN;C:\CRS30\BIN;C:\Program Files\Microsoft SQL Server\80\Tools\BINN;C:\Program Files\SecureCRT\;C:\PROGRA~1\SecureFX;C:\ResKit\;C:\PROGRA~1\CA\Common\SCANEN~1;C:\PROGRA~1\CA\eTrust\ANTIVI~1;c:\devtools

for /f "eol= tokens=1,2* delims=\" %%i in ('whoami.exe') do set username=%%j
for /f "eol= tokens=1,2,3,4,5* delims=^^/ " %%i in ("%date%") do set datetime=%%j-%%k-%%l
set errorlog= c:\winnt\temp\sherpaerr.tmp

IF {%1}=={} goto syntax
IF {%datetime%}=={help} goto syntax
IF {%datetime%}=={/?} goto syntax
IF {%datetime%}=={-?} goto syntax

choice  /tn,15 "%username%, this will update Sherpa, odd followed by even. Are you sure you want to do this?">\\dnrdc02\c$\markus\sherpa_out.txt
	for %%i in (1 3) do start psexec \\dnwbmtpa0%%i -u expeso\%username% -p %1 c:\bin\hotfix\webs.cmd %datetime% %username% %1
	for %%i in (1) do start psexec \\dnwbotpa0%%i -u expeso\%username% -p %1 c:\bin\hotfix\ops.cmd %datetime% %username% %1
	for %%i in (1 3) do start psexec \\dntvhtpa0%%i -u expeso\%username% -p %1 c:\bin\hotfix\TPA_travel.cmd %datetime% %username% %1


cls
Echo %username%, even servers will be finished soon.  
echo Press enter after all copy scripts are finished.
Echo Finished means verifying scripts on dnfil01\ops\hotfixed\%datetime%
Pause

goto eof

cls



	
:syntax
cls
echo Syntax:
	echo parameter - = hotfix folder (hotfix date) --> now automatic
	echo parameter - = username (no domain) --> now automatic
	echo parameter 1 = password
	echo help = this screen
	echo For example:
	echo sherpa_hotfix_script_scriptable.cmd %datetime% %username% Fu008@r3d 
	pause

:ErrCkOdd
	for %%a in (1) do sclist \\dnbottpa0%%a|grep -i migrationbot > %errorlog%
	for /f "eol= tokens=1,2,3,4,5,6,7* delims= " %%i in (%errorlog%) do echo %%j is %%i|if {%%i}=={stopped} echo %%j seems to be %%i 		Please check it.
	Goto EOF

:ErrCkEven
	for %%a in (2) do sclist \\dnbottpa0%%a|grep -i migrationbot > %errorlog%
	for /f "eol= tokens=1,2,3,4,5,6,7* delims= " %%i in (%errorlog%) do echo %%j is %%i|if {%%i}=={running} echo %%j seems to be %%i 	Please check it.
	goto EOF

:eof
