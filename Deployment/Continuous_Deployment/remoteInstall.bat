pushd \\chelappsbx001.karmalab.net\DeploymentAutomation_dogfood\Voyager_IIS\Deployment
if not exist d:\logroot\install md d:\logroot\install
if not exist c:\cct_ops md c:\cct_ops
powershell -ExecutionPolicy Bypass .\Voyager_upgrade_IIS_only.ps1 ##environment## ##BuildNum## < NUL 2>&1^| tee d:\logroot\install\remote_install_##environment##_##BuildNum##_tee.log
rem popd
rem pause
exit
