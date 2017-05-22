REM Norman Fletcher


@echo off

echo.
echo Running script to create branches...

REM setting login arguments
set host=karmalabproxy-perforce.sea.corp.expecn.com
set username=bpybuilder
set P4PASSWD=!Expedia1
set p4charset=utf8
set p4commandcharset=utf8
set p4PORT=perforce:1967
set p4editor=C:\Windows\system32\notepad.exe

REM setting/Validating arguments
set product=%1
set parentname=%2
set targetname=%3
set requestor=%4
if /I "%4"=="" goto MissingArgs
for %%a in (AIR,BFS,ELE,PAD) do (
    if "%product%"=="%%a" (
        goto ProductFound
    )
)
goto ProductNotFound
:ProductFound
set p4depot=1967
set ClientRoot=c:\P4\%p4depot%
if NOT exist %ClientRoot% goto ClientRootNotFound


REM starting operations


cd /d %ClientRoot%


REM Making sure user is logged in to Perforce
echo.
echo Making sure user is logged in to Perforce...
goto P4TestLogin

:P4TestLogin
echo Running "p4 login -s"
p4 login -s 2>&1 | findstr /ic:"ticket expires in"
IF NOT %ERRORLEVEL%==0 goto P4NotLoggedIn
goto P4IsLoggedIn

:P4NotLoggedIn
echo Please log in to Perforce...
p4 login -a bpybuilder

goto P4TestLogin

:P4IsLoggedIn
echo.
echo Successfully logged into Perforce, continuing...

rem p4 info

REM Forming branch name
set branchname=%product%%parentname%-to-%product%%targetname%
echo.
echo Branch name: %branchname%


REM Forming P4 paths
if /I "%product%"=="AIR" (
    set parentbranchpath=//depot/agtexpe/products/air/%parentname%/...
    set targetbranchpath=//depot/agtexpe/products/air/%targetname%/...
    set targetphysicalpath=depot\agtexpe\products\air
)
if /I "%product%"=="BFS" (
    set parentbranchpath=//depot/bfsexpe/products/air/%parentname%/...
    set targetbranchpath=//depot/bfsexpe/products/air/%targetname%/...
    set targetphysicalpath=depot\bfsexpe\products\air
)
if /I "%product%"=="ELE" (
    set parentbranchpath=//depot/ELE/products/expertweb/%parentname%/...
    set targetbranchpath=//depot/ELE/products/expertweb/%targetname%/...
    set targetphysicalpath=depot\ELE\products\expertweb
)
if /I "%product%"=="PAD" (
    set parentbranchpath=//depot/agtexpe/products/ProviderAdapter/%parentname%/...
    set targetbranchpath=//depot/agtexpe/products/ProviderAdapter/%targetname%/...
    set targetphysicalpath=depot\agtexpe\products\ProviderAdapter
)
if /I "parentbranchpath"=="" goto BranchPathError
echo.
echo Parent branch path: %parentbranchpath%
echo Target branch path: %targetbranchpath%


REM Checking for existing target branch path
echo.
echo Checking for existing target branch path...
echo Running "p4 files %targetbranchpath% 2>&1 | findstr /ic:"no such file(s)""   rem TO DEBUG run: p4 files %targetbranchpath% 2>&1
p4 files %targetbranchpath% 2>&1 | findstr /ic:"no such file(s)"
IF NOT %ERRORLEVEL%==0 (
    goto BranchPathExists
) else (
    echo Branch path not found, continuing...
)

REM Checking for existing parent branch path
echo.
echo Checking for existing parent branch path...
echo Running "p4 files %parentbranchpath% 2>&1 | findstr /ic:"no such file(s)""
p4 files %parentbranchpath% 2>&1 | findstr /ic:"no such file(s)"
IF %ERRORLEVEL%==0 (
    goto ParentBranchNotFound
) else (
    echo Parent branch path found, continuing...
)


REM Checking for existing target branch name
echo.
echo Checking for existing target branch name...
echo Running "p4 branches 2>&1 | findstr /ic:"%branchname%""
p4 branches 2>&1 | findstr /ic:"%branchname%"
IF NOT %ERRORLEVEL%==1 (
    goto BranchNameExists
) else (
    echo Branch name not found, continuing...
)


REM Creating branch details file
echo.
echo Creating branch details file...
if exist %temp%\branchdetails.txt del %temp%\branchdetails.txt
echo Branch: %branchname% > %temp%\branchdetails.txt
echo View: %parentbranchpath% %targetbranchpath% >> %temp%\branchdetails.txt


REM Creating branch
echo.
echo Creating branch...
echo Running "p4 branch %branchname%"
p4 branch -i < %temp%\branchdetails.txt
IF NOT %ERRORLEVEL%==0 goto Error


REM Creating changelist details file
echo.
echo Creating changelist details file...
if exist %temp%\changelistdetails.txt del %temp%\changelistdetails.txt
echo Change: new > %temp%\changelistdetails.txt
echo Description: Creating %branchname% branch per %requestor% >> %temp%\changelistdetails.txt


REM Creating changelist
echo.
echo Creating changelist...
if exist %temp%\changelistnumber.txt del %temp%\changelistnumber.txt
p4 change -i < %temp%\changelistdetails.txt > %temp%\changelistnumber.txt
IF NOT %ERRORLEVEL%==0 goto Error
for /f "tokens=1,2" %%i in (%temp%\changelistnumber.txt) do set changelist=%%j
echo.
echo Changelist: %changelist%


REM Creating maintenance file
echo.
echo Creating maintenance file...
echo Maintenance file: %targetphysicalpath%\%targetname%.maintenance
if exist %targetphysicalpath%\%targetname%.maintenance goto MaintenanceFileExists
if not exist %targetphysicalpath% md %targetphysicalpath%
echo 0 > %targetphysicalpath%\%targetname%.maintenance
p4 add -c %changelist% %targetphysicalpath%\%targetname%.maintenance
IF NOT %ERRORLEVEL%==0 goto Error


REM Integrating branch
echo.
echo Integrating branch...
echo Running "p4 integ -c %changelist% -v -b %branchname%"
p4 integ -c %changelist% -v -b %branchname% >nul
IF NOT %ERRORLEVEL%==0 goto Error


REM Submitting changelist
echo. 
echo Ready to submit?
echo To view or edit the pending changelist:
echo  1. Open another command window
echo  2. Navigate to your Perforce client folder
echo  3. Type "p4 change %changelist%"
echo.
echo Press [CTRL-C] to abort script
rem pause
echo.
echo Submitting changelist...
echo Running "p4 submit -c %changelist%"
p4 submit -c %changelist% >nul
IF NOT %ERRORLEVEL%==0 goto Error


REM Checking for p vs. v branch build.cmd conflict
echo.
echo Checking for p vs. v branch build.cmd conflict...
if /I "%parentname:~0,1%"=="v" (
    if /I "%targetname:~0,1%"=="p" call :EditBuildCMD-P
)
if /I "%parentname:~0,1%"=="p" (
    if /I "%targetname:~0,1%"=="v" call :EditBuildCMD-V
)
goto ContinueEditBuildCMD

:EditBuildCMD-P
echo.
echo Parent branch and Target branch have p vs. v conflict...
echo Edit build.cmd in the target branch:
echo   Remove the "V" from these lines:
echo     (lines 87 and 90) V%%BUILDSYSTEM_MAJORVERSION%%
echo   Change (line 228) -e "s/BUILD_MAJOR_VERSION=.*/BUILD_MAJOR_VERSION=%%BUILDSYSTEM_MAJORVERSION%%/" 
echo     To: Change %%BUILDSYSTEM_MAJORVERSION%% to 127
echo.
echo Syncing and opening %targetphysicalpath%\%targetname%\build.cmd
p4 sync %targetphysicalpath%\%targetname%\build.cmd
if exist %targetphysicalpath%\%targetname%\build.cmd (
	REM echo Please run the following commands:
  REM echo p4 edit %targetphysicalpath%\%targetname%\build.cmd
 REM  echo notepad %targetphysicalpath%\%targetname%\build.cmd
   rem echo Running "p4 submit %targetphysicalpath%\%targetname%\build.cmd"
   DEL build.cmd
   xcopy \\karmalab.net\builds\buildtools\REMTools\P4Branch\build.cmdP %targetphysicalpath%\%targetname%\ /E /C /I /Q /G /H /R /K /Y /Z /J
   REN build.cmdP build.cmd
   rem p4 add -c %targetphysicalpath%\%targetname%\build.cmd
   echo p4 submit %targetphysicalpath%\%targetname%\build.cmd
) else (
    echo %targetphysicalpath%\%targetname%\build.cmd does not exist or could not be opened!
)
goto :EOF

:EditBuildCMD-V
echo.
echo Parent branch and Target branch have v vs. p conflict...
echo Edit build.cmd in the target branch:
echo   Add the "V" to these lines:
echo     (lines 87 and 90) V%%BUILDSYSTEM_MAJORVERSION%%
echo   Change (line 228) -e "s/BUILD_MAJOR_VERSION=.*/BUILD_MAJOR_VERSION=127/" 
echo     To: Change 127 to %%BUILDSYSTEM_MAJORVERSION%%
echo.
echo Syncing and opening %targetphysicalpath%\%targetname%\build.cmd
p4 sync %targetphysicalpath%\%targetname%\build.cmd
if exist %targetphysicalpath%\%targetname%\build.cmd (
REM	echo Please run the following commands
REM   echo p4 edit %targetphysicalpath%\%targetname%\build.cmd
REM   echo notepad %targetphysicalpath%\%targetname%\build.cmd
   rem echo Running "p4 submit %targetphysicalpath%\%targetname%\build.cmd"

   DEL build.cmd
   xcopy \\karmalab.net\builds\buildtools\REMTools\P4Branch\build.cmdV %targetphysicalpath%\%targetname%\ /E /C /I /Q /G /H /R /K /Y /Z /J
   REN build.cmdV build.cmd
   rem p4 add -c %targetphysicalpath%\%targetname%\build.cmd
   echo p4 submit %targetphysicalpath%\%targetname%\build.cmd
) else (
    echo %targetphysicalpath%\%targetname%\build.cmd does not exist or could not be opened!
)
goto :EOF

:ContinueEditBuildCMD



echo.
echo Branch created successfully!
echo.
echo ***Add branch build to CruiseControl!***
echo.

goto END


:BranchNameExists
echo.
echo Configuration error (Please check Branch name already exists, login credentials, p4.ini settings )
goto END


:BranchPathError
echo.
echo ERROR: Could not create branch paths!
goto END


:BranchPathExists
echo.
echo ERROR: Branch path already exists!
goto END


:ClientRootNotFound
echo.
echo ERROR: The client root %ClientRoot% does not exist!
echo   Correct the client root path in this script.
goto END


:Error
echo.
echo ERROR: There was an error in the previous command!
goto END


:MaintenanceFileExists
echo.
echo ERROR: Maintenance file already exists!
goto END


:MissingArgs
echo.
echo ERROR: Arguments are missing!
echo.
echo Usage: branching.bat [Product] [Parent Name] [Target Name] [Requestor Alias]
echo Example: branching.bat AIR v3.25 v3.27 alias
goto END


:ParentBranchNotFound
echo.
echo ERROR: Parent branch path "%parentbranchpath%" does not exist!
goto END


:ProductNotFound
echo.
echo ERROR: Product "%product%" not in the list of available products!
echo   Correct the product name or update the available product list in this script.
echo   Product names are case sensitive.
goto END


:END
if exist %temp%\changelistdetails.txt del %temp%\changelistdetails.txt
if exist %temp%\changelistnumber.txt del %temp%\changelistnumber.txt
if exist %temp%\branchdetails.txt del %temp%\branchdetails.txt
