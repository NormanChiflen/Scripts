c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix on the Odd_EUR_Gats?
if errorlevel 2 goto :EOF

for /f %%a in (Odd_EUR_GATS.txt) do soon \\%%a 120 c:\bin\hotfix\gateway.cmd %1 %2 %3