c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update?
if errorlevel 2 goto :EOF

for /F %%a in (odd_na_bots.txt) do soon \\%%a 201 c:\localbin\hotfix\bot.cmd 02-06-04 mries $k3r123