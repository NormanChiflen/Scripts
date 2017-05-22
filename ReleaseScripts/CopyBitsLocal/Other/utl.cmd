c:\localbin\choice /t:n,10 Are you sure you want to copy Setup Bits to ALL Servers? This could take a while...
if errorlevel 2 goto :EOF

rem for /F %%i in (\\dnfil01\serverlists\dnutlper_all.txt) do rmdir \\%%i\d$\setup /Q /S
for /F %%i in (\\dnfil01\serverlists\dnutlper_all.txt) do del \\%%i\d$\setup\*.log /Q
for /F %%i in (\\dnfil01\serverlists\dnutlper_all.txt) do soon \\%%i 130 c:\bin\hotfix\copybitslocal.cmd %1 %2 & sleep 20