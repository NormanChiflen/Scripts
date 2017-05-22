setlocal
::Script to execute psexec to upload/execute a temp batch file 
:: 	Temp batch file will execute a powershell script using ExecutionPolicy Bypass
::	Powershell script will update cert thumbprint


rem Directions: Uncomment REM in front of the environment you want to execute again.

Rem set Prod=CHEXWBANGT001 CHEXWBANGT002 CHEXWBANGT003 CHEXWBANGT004 CHEXWBANGT005 CHEXWBANGT006
Rem set Iso-prod=CHEXWBANGTIP001
Rem set Training1=CHEXWBANGTTA001 CHEXWBANGTTA002
Rem set Training2=CHEXWBANGTTB001 CHEXWBANGTTB002



set serverlist=%DEV01% %DEV02% %DEV-TRN% %INT-AVT-Maui-1% %INT-MAUI-Maui-2% %INT-MILAN-Milan-1% %QA-03-Milan-2% %QA-01% %QA-02% %QA-04-QA-Perf%

:: Prod
:: Iso-prod
:: Training1
:: Training2

set BATCH_SCRIPT=c:\cct_ops\remote_execute.bat

set uname=%userdomain%\%username%
set /p password=What is your password?


@echo pushd \\chelappsbx001\DeploymentAutomation\ADFS>%BATCH_SCRIPT%
@echo if not exist e:\logroot\install md e:\logroot\install>>%BATCH_SCRIPT%
@echo echo. ^| powershell -ExecutionPolicy Bypass .\ADFS_cert_update.ps1 < NUL 2>&1 >>%BATCH_SCRIPT%
@echo popd>>%BATCH_SCRIPT%


for %%i in (%serverlist%) do psexec \\%%i -u %uname% -p %password% -h -f -c %BATCH_SCRIPT%  -w c:\cct_ops "cmd.exe /c %BATCH_SCRIPT%" & pause

endlocal