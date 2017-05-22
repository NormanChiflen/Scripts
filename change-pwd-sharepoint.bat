

@echo off

SET PATH=C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\BIN;%PATH%
SET DOMAIN=spdev
SET SSP=SSP1

rem *** Farm account (central admin app pool, timer jobs account)
set APP_POOL_CA_USER="%DOMAIN%\spfarm"
set APP_POOL_CA_PWD="pa$$w0rd"

rem *** SharePoint SSP Service Account
set SSPSVC_USER="%DOMAIN%\sspsvc"
set SSPSVC_PWD="pa$$w0rd"

rem *** SharePoint SSP Application Pool Account
SET APP_POOL_SSP_USER="%DOMAIN%\sspapppool"
SET APP_POOL_SSP_PWD="pa$$w0rd"

rem *** SharePoint Server Search Service Account 
set SEARCH_USER="%DOMAIN%\sspsearch"
set SEARCH_PWD="pa$$w0rd"

rem *** SharePoint Services Help Search Service Account 
set SEARCH_HELP_USER="%DOMAIN%\sphelpsearch"
set SEARCH_HELP_PWD="pa$$w0rd"

rem *** Default content access account for office search
set CONTENT_USER="%DOMAIN%\sspcontent"
set CONTENT_PWD="pa$$w0rd"

rem *** content access account for windows sharepoint services help search
set CONTENT_HELP_USER="%DOMAIN%\spcontentsearch"
set CONTENT_HELP_PWD="pa$$w0rd"

rem *** User profile import account
set PROFILE_IMPORT_USER="%DOMAIN%\sspuserprofilesvc"
set PROFILE_IMPORT_PWD="pa$$w0rd"

rem *** Portal application pool account
set APP_POOL_PORTAL_USER="%DOMAIN%\spportalapppool"
set APP_POOL_PORTAL_PWD="pa$$w0rd"

rem *** Teams sites application pool account
set APP_POOL_TEAMS_USER="%DOMAIN%\spcollabapppool"
set APP_POOL_TEAMS_PWD="pa$$w0rd"

rem *** My sites application pool account
set APP_POOL_MYSITE_USER="%DOMAIN%\spmysitesapppool"
set APP_POOL_MYSITE_PWD="pa$$w0rd"

rem *** Excel Services Unattended User Account
set SVC_EXCEL_USER="%DOMAIN%\SPSSAcct_dev"
set SVC_EXCEL_PWD="Pa$$w0rd"

goto startpoint
:startpoint


rem central admin
ECHO %DATE% %TIME%: Updating Central Admin password
stsadm -o updatefarmcredentials -userlogin %APP_POOL_CA_USER% -password %APP_POOL_CA_PWD% -identitytype configurableid
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Run "stsadm -o updatefarmcredentials -userlogin %APP_POOL_CA_USER% -password %APP_POOL_CA_PWD% -identitytype configurableid -local" on each WFE before continuing
pause
ECHO %DATE% %TIME%: Run "stsadm -o execadmsvcjobs" on each WFE before continuing.
pause

iisreset /noforce

rem application pools
ECHO %DATE% %TIME%: Updating app pool passwords for Portal
stsadm -o updateaccountpassword -userlogin %APP_POOL_PORTAL_USER% -password %APP_POOL_PORTAL_PWD% -noadmin
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating app pool passwords for Teams
stsadm -o updateaccountpassword -userlogin %APP_POOL_TEAMS_USER% -password %APP_POOL_TEAMS_PWD% -noadmin
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating app pool passwords for MySite
stsadm -o updateaccountpassword -userlogin %APP_POOL_MYSITE_USER% -password %APP_POOL_MYSITE_PWD% -noadmin
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating app pool passwords for SSP
stsadm -o updateaccountpassword -userlogin %APP_POOL_SSP_USER% -password %APP_POOL_SSP_PWD% -noadmin
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd


rem ssp - new
ECHO %DATE% %TIME%: Updating ssp password for new installs
stsadm -o editssp -title %SSP% -ssplogin %SSPSVC_USER% -ssppassword %SSPSVC_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd


rem osearch
ECHO %DATE% %TIME%: Updating osearch password
stsadm -o osearch -farmserviceaccount %SEARCH_USER% -farmservicepassword %SEARCH_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating default content access account
stsadm -o gl-updatedefaultcontentaccessaccount -username %CONTENT_USER% -password %CONTENT_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

iisreset /noforce

rem spsearch
ECHO %DATE% %TIME%: Updating spsearch password
stsadm -o spsearch -farmserviceaccount %SEARCH_HELP_USER% -farmservicepassword %SEARCH_HELP_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating spsearch content access account
stsadm -o spsearch -farmcontentaccessaccount %CONTENT_HELP_USER% -farmcontentaccesspassword %CONTENT_HELP_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating default profile import account
stsadm -o gl-setuserprofiledefaultaccessaccount -username %PROFILE_IMPORT_USER% -password %PROFILE_IMPORT_PWD% -sspname %SSP%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating excel services unattended service account
stsadm -o set-ecsexternaldata -ssp %SSP% -unattendedserviceaccountname %SVC_EXCEL_USER% -unattendedserviceaccountpassword %SVC_EXCEL_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

rem restarting IIS
ECHO %DATE% %TIME%: Doing soft restart of IIS

iisreset /noforce
echo on
goto end

:errhnd

echo An error occured - terminating script.

:end

To use this script on WSS just remove the unnecessary elements (lines with the following commands: gl-setuserprofiledefaultaccessaccount, gl-updatedefaultcontentaccessaccount, editssp, osearch, and set-ecsexternaldata).