c:\localbin\choice /t:n,10 Are you sure you want to run the Hotfix update against the FDS servers?
if errorlevel 2 goto :EOF

for /F %a in (odd_euro_fds.txt) do soon \\%a 122 c:\bin\hotfix\fds.cmd 12-18-03 johnmca Cutter45