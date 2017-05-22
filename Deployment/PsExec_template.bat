pushd \\chelappsbx001.karmalab.net\DeploymentAutomation\Voyager_IIS\Deployment
powershell -ExecutionPolicy Bypass .\Voyager_upgrade_IIS_only.ps1 ##ENV## ##BUILD_NUMBER##
popd
pause
exit
