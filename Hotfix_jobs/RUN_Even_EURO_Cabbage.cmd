c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update against the Cabbage servers?
if errorlevel 2 goto :EOF

for /F %%a in (even_euro_cabbage.txt) do soon \\%%a 122 c:\bin\hotfix\cabbage.cmd %1 %2 %3