c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update against the Bot servers?
if errorlevel 2 goto :EOF

for /F %%a in (even_euro_bots.txt) do soon \\%%a 201 c:\bin\hotfix\bot.cmd %1 %2 %3