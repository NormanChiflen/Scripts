c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update against the Bot servers?
if errorlevel 2 goto :EOF

for /F %%a in (Odd_EURO_BOTS.txt) do soon \\%%a 201 c:\bin\hotfix\bot.cmd 02-06-04 mries $k3r123