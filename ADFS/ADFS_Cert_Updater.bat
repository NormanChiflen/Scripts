setlocal
::Script to execute psexec to upload/execute a temp batch file 
:: 	Temp batch file will execute a powershell script using ExecutionPolicy Bypass
::	Powershell script will update cert thumbprint


set DEV01=CHELWBANGAT01 CHELWEBCRM77
set DEV02=CHELWBANGAT03 CHELWEBCRM07
set DEV-TRN=CHELWBANGAT18
set INT-AVT-Maui-1=CHELWBANGAT12 CHELWBANGAT13 CHELWBANGAT14
set INT-MAUI-Maui-2=CHELWBANGAT15 CHELWBANGAT16 CHELWBANGAT17
set INT-MILAN-Milan-1=CHELWEBE2ECCT30 CHELWEBE2ECCT31 CHELWEBE2ECCT32
set QA-03-Milan-2=CHELWBANGAT09 CHELWBANGAT10 CHELWBANGAT11
set QA-01=CHELWEBCRM79 CHELWEBCRM80 CHELWEBCRM82
set QA-02=CHELWBANGAT04 CHELWBANGAT05 CHELWBANGAT06
set QA-04-QA-Perf=CHELWBANGAT07



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


for %%i in (%serverlist%) do psexec \\%%i -u %uname% -p %password% -h -f -c %BATCH_SCRIPT%  -w c:\cct_ops "cmd.exe /c %BATCH_SCRIPT%" & start iexplore https://%%i.karmalab.net & pause

endlocal