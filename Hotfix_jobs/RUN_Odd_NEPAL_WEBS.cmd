c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update?
if errorlevel 2 goto :EOF

for /F %%a in (odd_nepal_webs.txt) do soon \\%%a 120 c:\bin\hotfix\webs.cmd %1 %2 %3