c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update against the FDS servers?
if errorlevel 2 goto :EOF

for /F %a in (even_euro_fds.txt) do soon 201 \\%a c:\bin\hotfix\fds.cmd %1 %2 %3