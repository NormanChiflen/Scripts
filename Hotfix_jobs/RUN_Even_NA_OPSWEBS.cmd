c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update?
if errorlevel 2 goto :EOF

for /F %%a in (even_na_opswebs.txt) do soon \\%%a 201 c:\bin\hotfix\ops.cmd %1 %2 %3