@echo off
set WebRootDrive=%1:
set IISPoolUser=%2
set IISPoolPassword=%3
Set ReleaseLocation=%4
set PADVersion=%5
set PADSourcePath=\\chelt2fil01\%ReleaseLocation%\depot\agtexpe\products\ProviderAdapter\%PADVersion%\deliverables\depot.agtexpe.products.provideradapter\%PADVersion%\Release\TravelFusionWebSvcIISPublish
set PADDestinationPath=%WebRootDrive%\TravelFusionWebSvcIISPublish


echo.
echo Using options:
echo WebRootDrive:      %WebRootDrive%
echo IISPoolUser:       %IISPoolUser%
echo IISPoolPassword:   [hidden]
echo ReleaseLocation:   %ReleaseLocation%
echo PADVersion:        %PADVersion%
echo.

if exist %PADDestinationPath%\bin cd /d %PADDestinationPath%\bin

echo Uninstalling IIS...
if exist %PADDestinationPath%\bin cmd /c IISsvc.bat -uninstall

echo Removing folder %PADDestinationPath%...
cd /d %WebRootDrive%\
if exist %PADDestinationPath% rd %PADDestinationPath% /s /q

echo Creating folder %PADDestinationPath%...
if not exist %PADDestinationPath% md %PADDestinationPath%

echo Copying files
echo   From: %PADSourcePath%
echo   To: %PADDestinationPath%
xcopy /e /Y %PADSourcePath% %PADDestinationPath%

echo Installing IIS...
cd /d %PADDestinationPath%\bin
cmd /c call IISsvc.bat /install /IIS7.ApplicationPool.ProcessModel.UserName=%IISPoolUser% /IIS7.ApplicationPool.ProcessModel.Password=%IISPoolPassword%

:end

echo.
echo Deployment completed.