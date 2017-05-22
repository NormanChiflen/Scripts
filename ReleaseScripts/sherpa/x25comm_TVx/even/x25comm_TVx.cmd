c:\localbin\choice /t:n,10 Are you sure you want to fix the x25comm\wssmsocketserver reg setting?
if errorlevel 2 goto :EOF
for %%i in (
DNTVHTPA02
DNTVHTPA04
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\x25comm_TVx\x25comm.ini