c:\localbin\choice /t:n,10 Are you sure you want to Flush ALL FDS Cache Files?
if errorlevel 2 goto :EOF

for /F %%a in (FDSServerList.txt) do del /Q \\%%a\fds\*.*
for /F %%a in (\\dnfil01\ops\scripts\ServerList.txt) do del /Q \\%%a\d$\fds\FDSSubscriptions\*.*