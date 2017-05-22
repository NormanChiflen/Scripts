c:\localbin\choice /t:n,10 Are you sure you want to stop the SiteScope monitors?
if errorlevel 2 goto :EOF

for /F %%a in (\\dnfil01\ops\scripts\releasescripts\sitescope\sitescope_serverlist.txt) do sc \\%%a stop sitescope


c:\localbin\choice /t:n,10 Are you sure you want to update the DLLs on the SiteScope monitors?
if errorlevel 2 goto :EOF

for /F %%a in (\\dnfil01\ops\scripts\releasescripts\sitescope\sitescope_serverlist.txt) do call :MUNGER %%a

c:\localbin\choice /t:n,10 Are you sure you want to start the SiteScope monitors?
if errorlevel 2 goto :EOF

for /F %%a in (\\dnfil01\ops\scripts\releasescripts\sitescope\sitescope_serverlist.txt) do sc \\%%a start sitescope

goto :EOF

:MUNGER
echo Create mg file from %1
dir /B \\%1\c$\sitescope\groups\*.mg > %1_mglist
echo Updating mg files on %1
for /F %%b in (%1_mglist) do munge scriptfile \\%1\c$\sitescope\groups\%%b

:EOF