@echo off
path=C:\Perl\bin\;C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;C:\MICROSOFT SITE SERVER\BIN;C:\CRS30\BIN;C:\Program Files\Microsoft SQL Server\80\Tools\BINN;C:\Program Files\SecureCRT\;C:\PROGRA~1\SecureFX;C:\ResKit\;C:\PROGRA~1\CA\Common\SCANEN~1;C:\PROGRA~1\CA\eTrust\ANTIVI~1;c:\devtools

for /f "eol= tokens=1,2* delims=\" %%i in ('whoami.exe') do set username=%%j
for /f "eol= tokens=1,2,3,4,5* delims=^^/ " %%i in ("%date%") do set datetime=%%j-%%k-%%l
set errorlog= c:\winnt\temp\sherpaerr.tmp
@REM for /f "eol= tokens=1,2* delims= " %%i in (\\dnfil01\ops\Scripts\Hotfix\sherpa\%2_ sherpa_ops.txt) do set servername=%%i

IF {%1}=={} goto syntax
IF {%2}=={} goto syntax
IF {%datetime%}=={help} goto syntax
IF {%datetime%}=={/?} goto syntax
IF {%datetime%}=={-?} goto syntax

choice  /tn,15 "%username%, this will update Sherpa %2 servers. Are you sure you want to do this?">\\dnrdc02\c$\markus\sherpa_out.txt

	for /f %%i in (\\dnfil01\ops\Scripts\Hotfix\sherpa\%2_ sherpa_ops.txt) do start psexec \\%%i -u expeso\%username% -p %1 c:\bin\hotfix\ops.cmd %datetime% %username% %1
	  
	Goto ErrCkservices
cls
Echo %username%, %2  ops servers will be finished soon.  

:syntax
cls
echo Syntax:
	echo parameter - = hotfix folder (hotfix date) --> now automatic
	echo parameter - = username (no domain) --> now automatic
	echo parameter 1 = password
	echo parameter 2 = odd or even
	echo help = this screen
	echo For example:
	echo sherpa_hotfix_script_scriptable.cmd %datetime% %username% Fu008@r3d odd
	pause

:ErrCkservices
	for /f %%a in (\\dnfil01\ops\Scripts\Hotfix\sherpa\%2_ sherpa_ops.txt) do sclist \\%%a|grep -i w3svc > %errorlog%
	for /f "eol= tokens=1,2,3,4,5,6,7* delims= " %%i in (%errorlog%) do echo %%j is %%i|if {%%i}=={stopped} echo %%j seems to be %%i 		Please check it.
	Goto EOF

:ErrCkfiles
	for /f "eol= tokens=1,2* delims= " %%i in ('grep -i ERROR \\dnfil01\ops\hotfixed\%datetime%\%servername%.txt) do set ERROR=%%i

If {%ERROR5}=={ERROR} goto CheckServer

:CheckServer

Echo Hey %username%, It looks like %servername% failed hotfixing.  Press enter to check.
pause
start notepad \\dnfil01\ops\hotfixed\%datetime%\%servername%.txt

goto eof

:eof
