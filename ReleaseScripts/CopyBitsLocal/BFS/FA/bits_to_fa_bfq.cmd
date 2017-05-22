c:\localbin\choice /t:n,10 Are you sure you want to copy Setup Bits to ALL Servers? This could take a while...
if errorlevel 2 goto :EOF


for /F %%i in (\\dnfil01\serverlists\all_farma_bfq.txt) do del \\%%i\d$\setup /Y
for /F %%i in (\\dnfil01\serverlists\all_farma_bfq.txt) do soon \\%%i 130 c:\bin\hotfix\copybitslocal.cmd %1 %2 & sleep 20