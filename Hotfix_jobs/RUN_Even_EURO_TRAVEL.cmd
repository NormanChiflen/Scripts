c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix on the Even_EU_Travel Servers?
if errorlevel 2 goto :EOF

for /f %%a in (Even_EUR_TRAVEL.txt) do soon \\%%a 120 c:\bin\hotfix\travel.cmd %1 %2 %3